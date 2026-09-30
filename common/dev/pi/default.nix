{
  lib,
  myLib,
  config,
  ...
}:
let
  agentsContent = ''
    This system runs NixOS. If a required development tool or package is not installed, use `nix shell nixpkgs#<package>` to provision and execute it.
    If a necessary repository is not available locally, you may clone it into /tmp/opencode and use it from there.
  '';
in
{
  options.custom.users = myLib.mkUserOption {
    options.dev.pi = {
      enable = lib.mkEnableOption "pi coding agent";
      models = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra models to register for the llama provider (llama models are added automatically when llama is enabled)";
      };
    };
  };

  config = {
    home-manager.users = myLib.mkForEachUsers config (user: user.custom.dev.pi.enable) (
      user:
      {
        lib,
        pkgs,
        config,
        ...
      }:
      let
        models =
          user.custom.dev.pi.models
          ++ lib.optionals (user.custom ? dev.llama && user.custom.dev.llama.enable) (
            map (m: m.name) user.custom.dev.llama.models
          );
      in
      {
        programs.pi-coding-agent = {
          enable = true;
          # pi が実行時に npm install する拡張の lifecycle script が node を呼ぶため
          # (例: pi-lens の @ast-grep/cli postinstall)
          # git は pi-undo のスナップショットが要求する
          # ast-grep は pi-lens の CLI ツール用 (npm 版は glibc 動的リンクで NixOS では動かない)
          extraPackages = [
            pkgs.nodejs
            pkgs.git
            pkgs.ast-grep
          ];
          settings = {
            # Automatic は kimi-k2.6 (廃止済み・410) を選ぶため明示する
            defaultProvider = "opencode-go";
            defaultModel = "deepseek-v4.1-flash";
            # 起動時の thinking レベル (モデルが対応する最大まで)
            defaultThinkingLevel = "max";
            # thinking ブロックを表示 (Ctrl+T でトグル)
            hideThinkingBlock = false;
            # Pi が画面を所有して transcript を再描画する (undo でメッセージが消えて見える)
            tuiMode = "fullscreen";
            # キャッシュミス/ウォーム/圧縮/復旧を通知 (OpenCode Go のコスト把握)
            showCacheMissNotices = true;
            # タブに進捗を表示 (OSC 9;4)
            terminal.showTerminalProgress = true;
            packages = [
              "npm:@dietrichgebert/ponytail"
              # Goal mode (opencode の goal-plugin 相当)
              "npm:pi-goal-x"
              # ストリーミング中の tokens/s / TTFT 表示 (opencode-tps 相当)
              "npm:pi-token-speed"
              # /btw: 本筋を脱線させないサイドスレッド
              "npm:@narumitw/pi-btw"
              # Web検索/fetch/GitHub clone/PDF/YouTube
              "npm:pi-web-access"
              # LSP/リンタ/型チェックのリアルタイム診断
              "npm:pi-lens"
              # 組み込みツールの描画だけ差し替える (diff/シンタックスハイライト)
              "npm:pi-pigment"
              # プロンプトキャッシュのヒット率改善 (プロンプト整形+統計。fix は models.json を書くので注意)
              "npm:pi-cache-optimizer"
              # サブエージェント (scout/researcher/worker/reviewer/oracle 等, 並列・バックグラウンド実行)
              "npm:pi-subagents"
              # Codex風の読み取り専用 /plan
              "npm:@narumitw/pi-plan-mode"
              # サブスク使用量表示 (OpenCode Go / Command Code GOAT 対応)
              "npm:@bacnh85/pi-sub"
              # 構造化質問ダイアログ (モデルが選択肢付きで聞いてくる)
              "npm:@juicesharp/rpiv-ask-user-question"
              # エディタ上のTodoパネル
              "npm:@juicesharp/rpiv-todo"
            ];
          };
          context = agentsContent;
          models = lib.mkIf (models != [ ]) {
            providers.llama = {
              baseUrl = "http://${user.custom.dev.llama.host}:${toString user.custom.dev.llama.port}/v1";
              api = "openai-completions";
              apiKey = "llama";
              models = builtins.map (model: {
                id = model;
                name = model;
                # llama-server は非対応モデルでは reasoning_effort を無視するだけなので
                # モデルごとに区別しない (opencode でも全モデルに同じ variants を付けていた)
                reasoning = true;
                # opencode の variants と同じ6択にする
                # off を書かない = reasoning_effort を送らない (テンプレート既定)
                thinkingLevelMap = {
                  minimal = null;
                  low = "low";
                  medium = "medium";
                  high = "high";
                  xhigh = "xhigh";
                  max = "max";
                };
              }) models;
            };
          };
        };

        # HM モジュールは既存ファイルを置き換えないため force する
        home.file."${config.home.homeDirectory}/.pi/agent/settings.json".force = true;
        home.file."${config.home.homeDirectory}/.pi/agent/AGENTS.md".force = true;
        home.file."${config.home.homeDirectory}/.pi/agent/models.json" = lib.mkIf (models != [ ]) {
          force = true;
        };

        # ツール出力を既定で全部展開する (Ctrl+O 相当をセッション開始時にON)
        home.file."${config.home.homeDirectory}/.pi/agent/extensions/expand-all.ts" = {
          force = true;
          text = ''
            import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

            export default function (pi: ExtensionAPI) {
              pi.on("session_start", (_event, ctx) => {
                ctx.ui.setToolsExpanded(true);
              });
            }
          '';
        };

        # opencode と同じ agenix 管理の API キーを、ファイルに残さない形で流用する
        home.file."${config.home.homeDirectory}/.pi/agent/auth.json" = {
          force = true;
          text = builtins.toJSON {
            "opencode-go" = {
              type = "api_key";
              key = "!${pkgs.jq}/bin/jq -r '.[\"opencode-go\"].key' \"$HOME/.local/share/opencode/auth.json\"";
            };
          };
        };

        home.persistence."/persist".directories = [ ".pi" ];
      }
    );
  };
}
