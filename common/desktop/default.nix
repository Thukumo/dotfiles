{
  lib,
  config,
  myLib,
  ...
}:

let
  # Injected into both the NixOS and home-manager module evaluations so that
  # system modules and per-user home-manager modules share the same helpers.
  desktopLib = {
    mkHome =
      condition: content:
      myLib.mkForEachUsers config (user: user.custom.desktop.enable && (condition user)) content;

    # ブラウザ名(desktop.mimeBrowser / desktop.browser の enum) → 起動コマンドと
    # ウインドウモードのフラグ。呼び出し側で null(未設定)は弾くこと。
    browserInfo =
      browser:
      let
        browsers = {
          chromium = {
            command = "chromium";
            newWindow = "--new-window";
            privateWindow = "--incognito";
          };
          google-chrome = {
            command = "google-chrome-stable";
            newWindow = "--new-window";
            privateWindow = "--incognito";
          };
          librewolf = {
            command = "librewolf";
            newWindow = "--new-window";
            privateWindow = "--private-window";
          };
        };
      in
      browsers.${browser};

    # ターミナル名(desktop.terminal の enum) → 起動コマンド。呼び出し側で null(未設定)は弾くこと。
    terminalInfo =
      terminal:
      let
        terminals = {
          foot = {
            command = "foot";
          };
        };
      in
      terminals.${terminal};

    # ランチャー名(desktop.launcher の enum) → 起動コマンド。呼び出し側で null(未設定)は弾くこと。
    launcherInfo =
      launcher:
      let
        launchers = {
          fuzzel = {
            command = "fuzzel";
          };
        };
      in
      launchers.${launcher};
  };
in
{
  options.custom.users = myLib.mkUserOption (
    { config, ... }:
    {
      options.desktop = {
        enable = lib.mkEnableOption "desktop environment";
        vr = {
          enable = lib.mkEnableOption "VR support";
          immersed.enable = lib.mkOption {
            type = lib.types.bool;
            default = config.desktop.vr.enable;
          };
        };
      };
    }
  );

  options.custom.desktop = {
    sunshine.enable = lib.mkEnableOption "";
    pipewire.enable = myLib.mkEnabledOption;
    anyEnabled = lib.mkOption {
      type = lib.types.bool;
      internal = true;
      default = false;
      description = "Whether any user has desktop enabled";
    };
  };

  imports = myLib.mkImportModules ./. [ ];

  config = lib.mkMerge [
    {
      custom.desktop.anyEnabled = lib.mkDefault (myLib.anyUser config (u: u.desktop.enable));

      _module.args.desktopLib = desktopLib;
      home-manager.users = myLib.mkForEachUsers config (user: user.custom.desktop.enable) (
        _user:
        { lib, config, ... }:
        {
          options.custom.desktop.persistDesktopEntries = lib.mkEnableOption "persistence for ~/.local/share/applications (Desktop Entries)";

          config = lib.mkMerge [
            { _module.args.desktopLib = desktopLib; }
            (lib.mkIf config.custom.desktop.persistDesktopEntries {
              home.persistence."/persist".directories = [
                ".local/share/applications"
              ];
            })
          ];
        }
      );
    }
    (lib.mkIf config.custom.desktop.anyEnabled {
      environment.pathsToLink = [
        "/share/xdg-desktop-portal"
        "/share/applications"
      ];

      services.udisks2.enable = true;
      services.gvfs.enable = true;

      security.polkit.enable = true;
    })
  ];
}
