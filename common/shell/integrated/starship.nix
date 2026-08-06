{ lib, ... }:

{
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
          when = "test -f /tmp/no-suspend -a ! -f /tmp/no-lock";
          symbol = "🌙 ";
          style = "bold blue";
          format = "[$symbol]($style)";
        };
      };
    };
  };
  # 内部でwhenを叩く時nuよりshを使わせた方が、全体として25msくらい早い
  programs.nushell.extraConfig = lib.mkAfter ''
    $env.STARSHIP_SHELL = "sh"
  '';
}
