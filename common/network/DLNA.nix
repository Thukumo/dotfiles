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
            in
            {
              inherit prefix resolvedPath;
            }
          ) u.network.dlna.mediaDirs
        ) enabledUsers
      );

      userMediaDirs = map (info: "${info.prefix},${info.resolvedPath}") userMediaInfo;

      # ACLルールの生成: 親ディレクトリの実行権限(x)と、メディアディレクトリ自体の読み取り・実行権限(rx)
      mkAclRules =
        path:
        let
          parts = lib.filter (s: s != "") (lib.splitString "/" path);
          # /home/user/Videos -> ["/", "/home", "/home/user"]
          prefixes = lib.genList (i: "/" + (lib.concatStringsSep "/" (lib.take i parts))) (lib.length parts);
          # ルートディレクトリなどは除外
          validParents = lib.filter (p: p != "" && p != "/") prefixes;
        in
        # 親ディレクトリには非再帰的に 'x' (a+), メディアディレクトリには再帰的に 'rx' かつデフォルトACLも設定 (A+)
        # maskを明示的に設定してACLを有効にする
        (map (p: "a+ ${p} - - - - u:minidlna:x,m::x") validParents) ++ [ "A+ ${path} - - - - u:minidlna:rx,m::rx,d:u:minidlna:rx,d:m::rx" ];

      aclRules = lib.unique (lib.flatten (map (info: mkAclRules info.resolvedPath) userMediaInfo));
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

      # サービスが /home を読み取れるようにする
      systemd.services.minidlna.serviceConfig.ProtectHome = "read-only";

      # 権限設定の改善: ACLを使用して、minidlnaユーザーにのみ必要最小限のアクセス権を付与する
      # これにより、ホームディレクトリの権限を0710に変更したり、ユーザーグループに加入させたりする必要がなくなる
      systemd.tmpfiles.rules = aclRules;

      boot.kernel.sysctl."fs.inotify.max_user_watches" = 524288;
    };
}
