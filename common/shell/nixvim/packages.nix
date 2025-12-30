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

    # その他言語サーバー
    nil
    lua-language-server
    clang-tools
    gopls

    # その他ツール
    watchexec
    deno
    wget
  ];
}
