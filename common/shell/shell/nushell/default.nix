{
  lib,
  config,
  myConfig,
  ...
}:
let
  isEnabled = myConfig.account.shell == "nushell";
in
{
  programs.nushell = {
    enable = isEnabled;
    settings = {
      history = {
        file_format = "sqlite";
        max_size = 1000000;
        # 端末間で履歴を分ける。plaintext では効かない (sqlite 専用)。
        isolation = true;
        # plaintext では isolation が効かないので、プロンプト毎の同期をやめ、起動/終了時だけマージする。
        # sqlite では sync 自体が no-op。
        sync_on_enter = false;
      };
      show_banner = false;
      completions = {
        case_sensitive = false;
        quick = true;
        partial = true;
        # algorithm = "fuzzy";
        algorithm = "prefix";
        external = {
          enable = true;
          max_results = 1000;
        };
      };
    };
  };
  xdg.configFile = {
    "nushell/history.sqlite3".source =
      config.lib.file.mkOutOfStoreSymlink "${config.xdg.stateHome}/nushell/history.sqlite3";
    "nushell/history.sqlite3-wal".source =
      config.lib.file.mkOutOfStoreSymlink "${config.xdg.stateHome}/nushell/history.sqlite3-wal";
  };
  home.persistence."/persist" = {
    directories = lib.optionals isEnabled [
      (lib.removePrefix "${config.home.homeDirectory}/" "${config.xdg.stateHome}/nushell")
    ];
  };
}
