{
  lib,
  config,
  inputs,
  desktopLib,
  ...
}:

let
  anyWinappsEnabled = lib.any (user: user.desktop.winapps.enable or false) (
    lib.attrValues config.custom.users
  );
in
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop.winapps = {
          enable = lib.mkEnableOption "WinApps RDP support";
          version = lib.mkOption {
            type = lib.types.str;
            default = "11";
            description = "Windows version (e.g. 10, 11, tiny11)";
          };
          ramSize = lib.mkOption {
            type = lib.types.str;
            default = "4G";
            description = "RAM size allocated to the Windows VM";
          };
          cpuCores = lib.mkOption {
            type = lib.types.str;
            default = "4";
            description = "CPU cores allocated to the Windows VM";
          };
          diskSize = lib.mkOption {
            type = lib.types.str;
            default = "64G";
            description = "Size of the primary hard disk";
          };
          username = lib.mkOption {
            type = lib.types.str;
            default = "MyWindowsUser";
            description = "Windows username";
          };
          password = lib.mkOption {
            type = lib.types.str;
            default = "MyWindowsPassword";
            description = "Windows password";
          };
          language = lib.mkOption {
            type = lib.types.str;
            default = "Japanese";
            description = "Windows system language";
          };
          sharedDir = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Directory to share with the Windows container. If empty, defaults to ~/shared.";
          };
          rdpScale = lib.mkOption {
            type = lib.types.str;
            default = "140";
            description = "Display scaling factor (e.g. '100', '140', '180')";
          };
          autopause = lib.mkEnableOption "automatic pausing of Windows when inactive";
          autopauseTime = lib.mkOption {
            type = lib.types.str;
            default = "300";
            description = "Duration of inactivity (in seconds) to tolerate before Windows is automatically paused";
          };
        };
      }
    );
  };

  config = {

    nix.settings = lib.mkIf anyWinappsEnabled {
      substituters = [ "https://winapps.cachix.org/" ];
      trusted-public-keys = [ "winapps.cachix.org-1:HI82jWrXZsQRar/PChgIx1unmuEsiQMQq+zt05CD36g=" ];
    };

    # Assign the 'kvm' group for QEMU KVM hardware acceleration
    users.users = lib.mapAttrs (_username: user: {
      extraGroups = lib.optionals user.desktop.winapps.enable [ "kvm" ];
    }) config.custom.users;

    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.winapps.enable) (
      user:
      { pkgs, config, ... }:
      let
        cfg = user.custom.desktop.winapps;
        sharedPath = if cfg.sharedDir != "" then cfg.sharedDir else "${config.home.homeDirectory}/shared";
      in
      {
        home.packages = with inputs.winapps.packages."${pkgs.stdenv.hostPlatform.system}"; [
          winapps
          winapps-launcher
        ];

        custom.desktop.persistDesktopEntries = true;

        home.persistence."/persist".directories = [
          ".local/share/winapps"
        ];

        programs.niri.settings.window-rules = [
          {
            matches = [ { app-id = "^xfreerdp[3]?$"; } ];
            open-on-workspace = "background";
          }
        ];

        # Create the shared directory if it doesn't exist
        systemd.user.tmpfiles.rules = [
          "d ${sharedPath} 0755 - - - -"
        ];

        # Declaratively define docker-compose.yaml for WinApps
        # Using compose.yaml instead of systemd Quadlet prevents auto-start on login
        # and allows WinApps to natively start/pause the VM on-demand.
        xdg.configFile."winapps/compose.yaml".text = ''
          services:
            windows:
              image: ghcr.io/dockur/windows:latest
              container_name: WinApps
              environment:
                VERSION: "${cfg.version}"
                RAM_SIZE: "${cfg.ramSize}"
                CPU_CORES: "${cfg.cpuCores}"
                DISK_SIZE: "${cfg.diskSize}"
                USERNAME: "${cfg.username}"
                PASSWORD: "${cfg.password}"
                LANGUAGE: "${cfg.language}"
                HOME: "${config.home.homeDirectory}"
              ports:
                - "127.0.0.1:8006:8006"
                - "127.0.0.1:3389:3389/tcp"
                - "127.0.0.1:3389:3389/udp"
              volumes:
                - "winapps_data:/storage"
                - "${sharedPath}:/shared"
                - "${config.xdg.configHome}/winapps/oem:/oem"
              cap_add:
                - NET_ADMIN
              devices:
                - /dev/kvm
                - /dev/net/tun
              stop_grace_period: 120s
              restart: on-failure

          volumes:
            winapps_data:
        '';

        # Declaratively define winapps config file
        xdg.configFile."winapps/winapps.conf".text = ''
          RDP_USER="${cfg.username}"
          RDP_PASS="${cfg.password}"
          RDP_IP="127.0.0.1"
          WAFLAVOR="podman"
          RDP_SCALE="${cfg.rdpScale}"
          RDP_FLAGS="/cert:tofu /sound /microphone +home-drive"
          HIDEF="off"
          DEBUG="true"
          AUTOPAUSE="${if cfg.autopause then "on" else "off"}"
          AUTOPAUSE_TIME="${cfg.autopauseTime}"
          PORT_TIMEOUT="5"
          RDP_TIMEOUT="120"
          APP_SCAN_TIMEOUT="180"
          BOOT_TIMEOUT="120"
        '';
      }
    );
  };
}
