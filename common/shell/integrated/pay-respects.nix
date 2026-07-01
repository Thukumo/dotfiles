{
  pkgs,
  ...
}:

{
  programs.pay-respects = {
    enable = true;
    enableNushellIntegration = false;
  };
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
}
