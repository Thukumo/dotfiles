{
  pkgs,
  ...
}:

{
  programs.pay-respects = {
    enable = true;
    # 公式nushell統合は使わない。生成スクリプトが _PR_SHELL=nushell を渡し、
    # pay-respects が `nushell` 実行ファイルのspawnを試みてpanicする
    # (binary名は nu。_PR_SHELL=nu なら動作確認済み)。自作シムで "nu" を渡す。
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
