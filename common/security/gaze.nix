{
  lib,
  config,
  inputs,
  ...
}:
let
  myCfg = config.custom.security.gaze;
in
{
  imports = [ inputs.gaze.nixosModules.default ];

  options.custom.security.gaze = {
    enable = lib.mkEnableOption "Gaze facial authentication (face unlock)";
    gui = lib.mkEnableOption "the Gaze GTK GUI for enrolling faces" // {
      default = true;
    };

    # greetdがmlockall(MCL_CURRENT|MCL_FUTURE)するので、ここにloginを入れると物理メモリをいっぱい食われる
    pamServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "sudo"
        "polkit-1"
        "hyprlock"
      ];
      description = "PAM services to enable Gaze face authentication for.";
    };

    rgb = lib.mkOption {
      type = lib.types.str;
      default = "primary";
      description = ''
        RGB camera source for Gaze. A GStreamer source, `primary`
        (PipeWire), a `usb:VVVV:PPPP` VID:PID, or a `/dev/video*` node.
        Set to "" to disable RGB and use the IR camera only.
      '';
    };

    ir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Infrared (Windows Hello) camera source, e.g. `"usb:0bda:558b"` or
        `"/dev/video3"`. Resolved by VID:PID to the mono/IR node. `null`
        disables the IR camera.
      '';
    };

    emitterEnabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Drive the IR emitter (IR LED) during authentication. Needed when the
        camera does not auto-light its infrared LED on streaming start
        (otherwise IR frames come out black and are rejected as too dark).
        Requires `ir` to be set.
      '';
    };

    darkLumaThreshold = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = ''
        Override `[cameras] dark_luma_threshold`. IR cameras produce
        inherently dim frames, so a low value (or 0) prevents spurious
        `TooDark` rejections. `null` leaves the upstream default (20).
      '';
    };

    securityLevel = lib.mkOption {
      type = lib.types.enum [
        "low"
        "medium"
        "high"
        "maximum"
        "custom"
      ];
      default = "maximum";
      description = ''
        Gaze security level. `low`/`medium` use MobileFaceNet (faster),
        `high`/`maximum` use ResNet50 (more accurate, stricter). Ignored
        when `securityLevel = "custom"` (set thresholds via
        `services.gaze.settings.security` directly).
      '';
    };

    encryptTemplates = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Encrypt enrolled face templates at rest with a TPM 2.0-sealed key.
        Defaults to `security.tpm2.enable`. Fail-closed: if no usable
        TPM is found the daemon refuses to start.
      '';
    };

    customSecurity = lib.mkOption {
      type = lib.types.submodule {
        options = {
          detector = lib.mkOption {
            type = lib.types.enum [
              "standard"
              "accurate"
            ];
            default = "accurate";
            description = "Face detector quality for `securityLevel = \"custom\"`.";
          };
          recognizer = lib.mkOption {
            type = lib.types.enum [
              "standard"
              "accurate"
            ];
            default = "accurate";
            description = "Embedding model for `securityLevel = \"custom\"`. `accurate` = ResNet50.";
          };
          threshold = lib.mkOption {
            type = lib.types.float;
            default = 0.4;
            description = "Match threshold (0-1) for `securityLevel = \"custom\"`.";
          };
          hybridPolicy = lib.mkOption {
            type = lib.types.enum [
              "default"
              "or"
              "fallback_on_dark"
              "and"
            ];
            default = "fallback_on_dark";
            description = "How RGB and IR results combine when both cameras are set.";
          };
        };
      };
      default = { };
      description = ''
        Fine-grained tuning, used only when `securityLevel = "custom"`.
        Keeps the stronger ResNet50 model while letting the threshold drop
        to a value this IR camera can meet.
      '';
    };
  };

  config = lib.mkMerge [
    {
      custom.security.gaze.encryptTemplates = lib.mkDefault config.security.tpm2.enable;
    }
    (lib.mkIf myCfg.enable {
      services.gaze = {
        enable = true;
        gui.enable = myCfg.gui;
        mutableConfig = false;
        pam.defaultServices = myCfg.pamServices;

        settings = {
          security =
            if myCfg.securityLevel == "custom" then
              {
                level = "custom";
                detector = myCfg.customSecurity.detector;
                recognizer = myCfg.customSecurity.recognizer;
                threshold = myCfg.customSecurity.threshold;
                hybrid_policy = myCfg.customSecurity.hybridPolicy;
              }
            else
              {
                level = myCfg.securityLevel;
              };
          storage.encrypt_templates = myCfg.encryptTemplates;
          cameras = {
            inherit (myCfg) rgb;
          }
          // lib.optionalAttrs (myCfg.ir != null) {
            inherit (myCfg) ir;
            emitter_enabled = myCfg.emitterEnabled;
          }
          // lib.optionalAttrs (myCfg.darkLumaThreshold != null) {
            dark_luma_threshold = myCfg.darkLumaThreshold;
          };
        };
      };

      environment.persistence."/persist".directories = [
        "/var/lib/gaze"
        "/var/cache/gaze"
      ];
    })
  ];
}
