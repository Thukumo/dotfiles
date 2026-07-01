_:

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
}
