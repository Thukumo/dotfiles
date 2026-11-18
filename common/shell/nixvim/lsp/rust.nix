{ pkgs, lib, ... }:

let
  # proc-macro/build script のリンクにだけ cc を使わせる。
  # devshell の cc を優先させるため末尾に足す
  rust-analyzer = pkgs.writeShellScriptBin "rust-analyzer" ''
    export PATH="$PATH:${lib.makeBinPath [ pkgs.stdenv.cc ]}"
    exec ${pkgs.rust-analyzer}/bin/rust-analyzer "$@"
  '';
in
{
  programs.nixvim.plugins.lsp.servers.rust_analyzer = {
    enable = true;
    package = rust-analyzer;
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
      cargo.features = "all";
      procMacro.enable = true;
    };
  };
}
