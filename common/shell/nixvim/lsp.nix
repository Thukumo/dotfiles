{ ... }:

{
  programs.nixvim.plugins = {
    lsp = {
      enable = true;
      servers = {
        rust_analyzer = {
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
            };
            procMacro = {
              enable = true;
            };
          };
        };
        nil_ls = {
          enable = true;
          settings = {
            diagnostics.enable = true;
            nix.flake.autoArchive = true;
          };
        };
        lua_ls = {
          enable = true;
          settings.Lua = {
            diagnostics = {
              globals = [ "vim" ];
              enable = true;
            };
            workspace.checkThirdParty = false;
          };
        };
        clangd = {
          enable = true;
          cmd = [
            "clangd"
            "--background-index"
            "--clang-tidy"
          ];
        };
        gopls = {
          enable = true;
          settings = {
            analyses = {
              unusedparams = true;
              shadow = true;
            };
            staticcheck = true;
          };
        };
      };
    };
    lazydev.enable = false;
  };
}
