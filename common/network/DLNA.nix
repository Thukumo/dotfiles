{
  lib,
  config,
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

      userMediaDirs = lib.concatLists (
        lib.mapAttrsToList (
          name: u:
          let
            homeDir = config.users.users.${name}.home;
          in
          map (
            val:
            let
              parts = lib.splitString "," val;
              # コンマが含まれていない場合はアサートでビルドを落とす
              _ = assert lib.assertMsg (lib.length parts >= 2) "DLNA mediaDir '${val}' must be in 'PREFIX,PATH' format (e.g. 'V,Documents/mov')"; parts;

              prefix = lib.head parts;
              # パス自体にコンマが含まれるケースを考慮して再結合
              path = lib.concatStringsSep "," (lib.tail parts);
              resolvedPath = if lib.hasPrefix "/" path then path else "${homeDir}/${path}";
            in
            "${prefix},${resolvedPath}"
          ) u.network.dlna.mediaDirs
        ) enabledUsers
      );
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

      # minidlna ユーザーが各ユーザーのホーム配下にアクセスできるように、該当ユーザーのグループに加入させる
      users.users.minidlna.extraGroups = lib.attrNames enabledUsers;
      users.groups = lib.mapAttrs (name: _: {
        members = [ "minidlna" ];
      }) enabledUsers;

      # ホームディレクトリ自体の権限を 710 に設定して、グループメンバー (minidlna) が中に入れるようにする
      systemd.tmpfiles.rules = lib.mapAttrsToList (name: _: "d /home/${name} 0710 ${name} users - -") enabledUsers;

      boot.kernel.sysctl."fs.inotify.max_user_watches" = 524288;
    };
}
