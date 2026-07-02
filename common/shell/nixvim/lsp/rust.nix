_:

{
  programs.nixvim.plugins.lsp.servers.rust_analyzer = {
    enable = true;
    installCargo = false;
    installRustc = false;
    settings = {
      check = {
        command = "clippy";
        allTargets = true;
      };
      diagnostics = {
        enable = true;
        experimental.enable = true;
      };
      cargo = {
        allFeatures = true;
        loadOutDirsFromCheck = true;
        # sysrootSrc = "${pkgs.rustPlatform.rustLibSrc}";
      };
      procMacro = {
        enable = true;
        serverPath = "rust-analyzer";
      };
    };
  };
}
