{ pkgs, ... }:

{
  programs.nixvim.extraPackages = with pkgs; [
    # CLI補助
    ripgrep
    fd

    # Rustツールチェーン
    cargo
    rustc
    rustfmt
    rust-analyzer
    clippy

    # その他言語サーバー
    nil
    lua-language-server
    clang-tools
    pyright
    ruff

    # その他ツール
    watchexec
    deno
    wget
  ];
}
