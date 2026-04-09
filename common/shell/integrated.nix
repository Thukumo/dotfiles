{ pkgs, ... }:

{
  home.persistence."/persist".directories = [
    ".local/share/direnv"
    ".local/share/zoxide"
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.nix-your-shell = {
    enable = true;
  };

  programs.pay-respects = {
    enable = true;
    enableNushellIntegration = false;
  };
  # for pay-respects +
  programs.nushell.extraConfig = ''
    def --env f [] {
      let last_cmd = (history | last 2 | first | get command)
      let result = (with-env {
          _PR_LAST_COMMAND: $last_cmd,
          _PR_SHELL: "nu"
      } {
          ${pkgs.pay-respects}/bin/pay-respects
      })

      if ($result | is-not-empty) and ($result | path exists) {
          cd $result
      }
    }
  '';

  programs.skim = {
    enable = true;
  };

  programs.starship = {
    enable = true;
    settings = {
      format = "$all$custom$character";
      custom = {
        awake = {
          when = "test -f /tmp/no-lock";
          symbol = "☀️ ";
          style = "bold yellow";
          format = "[$symbol]($style)";
        };
        insomnia = {
          when = "test -f /tmp/no-suspend && [ ! -f /tmp/no-lock ]";
          symbol = "🌙 ";
          style = "bold blue";
          format = "[$symbol]($style)";
        };
      };
    };
  };

  programs.zoxide = {
    enable = true;
    options = [
      "--cmd cd"
    ];
  };

  programs.carapace.enable = true;
}
