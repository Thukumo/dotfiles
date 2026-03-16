{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.network.dlna = {
          enable = lib.mkEnableOption "DLNA Server for this user";
          mediaDirs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [ "V,Documents/mov" ];
            description = ''
              Media directories for this user.
              Must be prefixed with V, P, or A followed by a comma (e.g., "V,path/to/video").
              Relative paths are resolved to the user's home.
            '';
          };
        };
      }
    );
  };

  config =
    let
      enabledUsers = lib.filterAttrs (_: u: u.network.dlna.enable) config.custom.users;
      anyUserEnabled = enabledUsers != { };

      # 解析されたメディアディレクトリ情報
      userMediaInfo = lib.flatten (
        lib.mapAttrsToList (
          name: u:
          let
            homeDir = config.users.users.${name}.home;
          in
          map (
            val:
            let
              parts = lib.splitString "," val;
              _ = assert lib.assertMsg (lib.length parts >= 2) "DLNA mediaDir '${val}' must be in 'PREFIX,PATH' format (e.g. 'V,Documents/mov')"; parts;

              prefix = lib.head parts;
              path = lib.concatStringsSep "," (lib.tail parts);
              resolvedPath = if lib.hasPrefix "/" path then path else "${homeDir}/${path}";
              # サービス内部での中立なマウント先（親の 700 権限をバイパスするため）
              warpPath = "/run/minidlna/warp_${lib.replaceStrings [ "/" ] [ "_" ] (lib.removePrefix "/" resolvedPath)}";
            in
            {
              inherit prefix resolvedPath warpPath;
            }
          ) u.network.dlna.mediaDirs
        ) enabledUsers
      );

      # minidlnaに教える実際のパス（ワープ先を使用）
      userMediaDirs = map (info: "${info.prefix},${info.warpPath}") userMediaInfo;

      # 権限設定: メディアディレクトリ自体に 'rx' 権限を付与し、デフォルトACLも設定して新規ファイルに対応
      aclRules = map (info: "A+ ${info.resolvedPath} - - - - u:minidlna:rx,m::rx,d:u:minidlna:rx,d:m::rx") userMediaInfo;
    in
    lib.mkIf anyUserEnabled {
      services.minidlna = {
        enable = true;
        openFirewall = true;
        settings = {
          friendly_name = config.networking.hostName;
          media_dir = userMediaDirs;
          inotify = "yes";
          notify_interval = 30;
        };
      };

      systemd.services.minidlna.serviceConfig = {
        # メディアディレクトリを直接サービスのファイルシステム名前空間にマウントする
        # これにより、親ディレクトリの権限（0700など）を完全に無視してアクセス可能になる
        # source:dest の形式で指定
        BindReadOnlyPaths = map (info: "${info.resolvedPath}:${info.warpPath}") userMediaInfo;
      };

      # 権限設定の改善: ACLを使用して、minidlnaユーザーにのみ必要最小限のアクセス権を付与する
      # これにより、ホームディレクトリの権限を0710に変更したり、ユーザーグループに加入させたりする必要がなくなる
      systemd.tmpfiles.rules = aclRules;

      boot.kernel.sysctl."fs.inotify.max_user_watches" = 524288;
    };
}
