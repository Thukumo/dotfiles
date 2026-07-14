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
          jpKeyboard = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to use Japanese keyboard layout (JIS) in RDP session";
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
      {
        pkgs,
        config,
        lib,
        ...
      }:
      let
        cfg = user.custom.desktop.winapps;
        sharedPath = if cfg.sharedDir != "" then cfg.sharedDir else "${config.home.homeDirectory}/shared";
      in
      {
        home.packages = with inputs.winapps.packages."${pkgs.stdenv.hostPlatform.system}"; [
          (winapps.overrideAttrs (oldAttrs: {
            postFixup = (oldAttrs.postFixup or "") + ''
              substituteInPlace $out/bin/.winapps-setup-wrapped \
                --replace-fail "sed -i 's/\r//g' \"\$DETECTED_FILE_PATH\"" \
                  "if ${pkgs.file}/bin/file \"\$DETECTED_FILE_PATH\" | grep -q 'Non-ISO'; then ${pkgs.glibc.bin}/bin/iconv -f CP932 -t UTF-8 \"\$DETECTED_FILE_PATH\" > \"\$DETECTED_FILE_PATH.tmp\" 2>/dev/null && mv \"\$DETECTED_FILE_PATH.tmp\" \"\$DETECTED_FILE_PATH\"; fi; sed -i 's/\r//g' \"\$DETECTED_FILE_PATH\""
            '';
          }))
          winapps-launcher
        ];

        custom.desktop.persistDesktopEntries = true;

        home.persistence."/persist".directories = [
          ".local/share/winapps"
          (lib.removePrefix "${config.home.homeDirectory}/" sharedPath)
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
          unset WAYLAND_DISPLAY
          RDP_SCALE="${cfg.rdpScale}"
          RDP_FLAGS="/cert:tofu /sound /microphone${lib.optionalString cfg.jpKeyboard " /kbd:0x00000411"}"
          RDP_FLAGS_WINDOWS="/f"
          HIDEF="off"
          DEBUG="true"
          AUTOPAUSE="${if cfg.autopause then "on" else "off"}"
          AUTOPAUSE_TIME="${cfg.autopauseTime}"
          PORT_TIMEOUT="5"
          RDP_TIMEOUT="120"
          APP_SCAN_TIMEOUT="180"
          BOOT_TIMEOUT="120"
        '';

        # Declaratively define Apple Music integration
        home.file.".local/share/winapps/apps/applemusic/info".text = ''
          # GNOME shortcut name
          NAME="Apple Music"

          # Used for descriptions and window class
          FULL_NAME="Apple Music"

          # The executable alias inside windows registry
          WIN_EXECUTABLE="||AppleMusic"

          # GNOME categories
          CATEGORIES="WinApps;Windows;AudioVideo;Audio;Music"

          # GNOME mimetypes
          MIME_TYPES=""
        '';

        xdg.desktopEntries.applemusic = {
          name = "Apple Music";
          exec = "winapps applemusic %F";
          terminal = false;
          icon = "multimedia-audio-player";
          comment = "Listen to Apple Music";
          categories = [
            "AudioVideo"
            "Audio"
            "Music"
            "Player"
          ];
        };

        home.activation.copyWinappsOem = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          rm -rf ${config.xdg.configHome}/winapps/oem
          mkdir -p ${config.xdg.configHome}/winapps/oem

          cp -f ${pkgs.writeText "apple_music_remoteapp.reg" ''
            Windows Registry Editor Version 5.00

            [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList\Applications\AppleMusic]
            "Name"="Apple Music"
            "Path"="C:\\Windows\\System32\\cmd.exe"
            "RequiredCommandLine"="/c start musics://"
            "CommandLineSetting"=dword:00000002
            "ShowInPortal"=dword:00000001

            [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList]
            "fDisabledAllowList"=dword:00000001
          ''} ${config.xdg.configHome}/winapps/oem/apple_music_remoteapp.reg

          cp -f ${pkgs.writeText "install.bat" ''
            @echo off
            reg import C:\OEM\apple_music_remoteapp.reg
          ''} ${config.xdg.configHome}/winapps/oem/install.bat

          chmod 644 ${config.xdg.configHome}/winapps/oem/apple_music_remoteapp.reg
          chmod 644 ${config.xdg.configHome}/winapps/oem/install.bat
        '';
      }
    );
  };
}
