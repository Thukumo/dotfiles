{
  pkgs,
  lib,
  osConfig,
  config,
  ...
}:
let
  isEnabled = osConfig.users.users.${config.home.username}.shell == pkgs.nushell;
in
{
  programs.nushell = {
    enable = isEnabled;
    extraEnv = ''
      if (which gh | is-empty) == false {
        try {
          let token = (gh auth token | str trim)
          if ($token | is-empty) == false {
            $env.NIX_CONFIG = $"access-tokens = github.com=($token)"
          }
        }
      }
    '';
    settings = {
      history = {
        file_format = "sqlite";
        max_size = 1000000;
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
