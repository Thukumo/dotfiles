{
  description = "NixOS Flake";

  inputs = {
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      # 公式 template が follows 入り。nixpkgs に無い hook パッケージは警告付きで skip される
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      # affinity-nix の dev 用 input を root へ寄せるためだけの input。
      # dev 用ツールのラッパーで本体ビルドには関与しないため follows して問題ない
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    affinity-nix = {
      url = "github:mrshmllow/affinity-nix";
      # overlay 経由の利用ではパッケージがシステム側の pkgs でビルドされるため安全
      inputs.nixpkgs.follows = "nixpkgs";
      # dev 用 input も root へ集約（どちらも本体ビルドには使われない）
      inputs.git-hooks.follows = "git-hooks";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    nixvim.url = "github:nix-community/nixvim";

    gaze = {
      url = "github:GunduLabs/gaze";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      # module はシステム側の pkgs で niri をビルドするため安全（内部の nixpkgs-stable は別途残る）
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ragenix は内部で allowAliases = false にしてビルドしており、follows すると
    # isLinux エイリアスの無い新 nixpkgs で rust-overlay のビルドが壊れるため follows しない
    ragenix.url = "github:yaxitech/ragenix";

    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      # installer.sh で動かす CLI 専用で、nixpkgs はそのビルドにしか使わない
      inputs.nixpkgs.follows = "nixpkgs";
      # nixos-stable は upstream のテスト専用 input なので root に寄せて重複を消す
      inputs.nixos-stable.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix/pull/2348/head";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      # url = "github:nix-community/NUR";
      url = "github:thukumo/nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    winapps = {
      url = "github:winapps-org/winapps";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sidra = {
      url = "github:wimpysworld/sidra";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nowplaying = {
      url = "github:Thukumo/nowplaying";
      # nixpkgs input がひとつだけで、version に依存しない API しか使わないため安全
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    {
      self,
      git-hooks,
      nixpkgs,
      home-manager,
      impermanence,
      nixvim,
      niri,
      ragenix,
      nix-index-database,
      disko,
      lanzaboote,
      stylix,
      microvm,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;
      myLib = import ./helper/myLib.nix { inherit lib; };
      hostDirectories = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts);
      hosts = lib.mapAttrs (name: _: import (./hosts + "/${name}") inputs) hostDirectories;

      commonModules = name: [
        ./common
        ./const
        {
          networking.hostName = name;
        }

        home-manager.nixosModules.home-manager
        {
          home-manager.sharedModules = [
            nixvim.homeModules.nixvim
            niri.homeModules.niri
            ragenix.homeManagerModules.default
          ];
        }

        impermanence.nixosModules.impermanence

        nix-index-database.nixosModules.nix-index
        { programs.nix-index-database.comma.enable = true; }

        ragenix.nixosModules.default
        disko.nixosModules.disko
        lanzaboote.nixosModules.lanzaboote
        stylix.nixosModules.stylix
        microvm.nixosModules.host
      ];

      mkHost =
        name: host:
        lib.nixosSystem {
          inherit (host) system;
          specialArgs = {
            inherit inputs myLib;
          }
          // (host.specialArgs or { });
          modules = (commonModules name) ++ (host.modules or [ ]);
        };

      hostConfigs = lib.mapAttrs mkHost hosts;

      systems = lib.unique (builtins.catAttrs "system" (builtins.attrValues hosts));
    in
    {
      formatter = lib.genAttrs systems (
        system:
        inputs.treefmt-nix.lib.mkWrapper nixpkgs.legacyPackages.${system} {
          projectRootFile = "flake.nix";
          programs = {
            nixfmt.enable = true;
            deadnix.enable = true;
            statix.enable = true;
          };
        }
      );

      # Force the NixOS assertions for every host. This keeps the secret
      # access checks (LoadCredential, owner/mode, acceptedRisk, consumers)
      # covered by `nix flake check` without building the full systems.
      checks = lib.genAttrs systems (
        system:
        let
          checkHosts = lib.filterAttrs (_: host: host.system == system) hosts;
        in
        lib.mapAttrs' (
          hostName: _:
          let
            cfg = hostConfigs.${hostName};
            failedAssertions = lib.filter (a: !a.assertion) cfg.config.assertions;
            assertionMessage = lib.concatMapStringsSep "\n" (a: a.message) failedAssertions;
            assertionsOk = lib.boolToString (lib.asserts.assertMsg (failedAssertions == [ ]) assertionMessage);
          in
          lib.nameValuePair "${hostName}-assertions" (
            cfg.pkgs.runCommand "${hostName}-assertions" { inherit assertionsOk; } "touch $out"
          )
        ) checkHosts
      );

      devShells = lib.genAttrs systems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          hook = git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixfmt.enable = true;
              deadnix = {
                enable = true;
                settings.edit = true;
              };
              statix = {
                enable = true;
                name = "statix fix";
                entry = "${pkgs.statix}/bin/statix fix";
              };
              gen-docs = {
                enable = true;
                files = "\\.nix$";
                require_serial = true;
                name = "Generate documentation";
                entry = "${
                  pkgs.writeShellApplication {
                    name = "gen-docs";
                    runtimeInputs = with pkgs; [
                      nix
                      git
                      diffutils
                      gnused
                      coreutils
                    ];
                    # レンダリング本体は flake の genDocs / genSecretsDocs 出力にある
                    text = ''
                      TEMP_FILE=$(mktemp)
                      SECRETS_TEMP_FILE=$(mktemp)
                      trap 'rm -f "$TEMP_FILE" "$SECRETS_TEMP_FILE"' EXIT

                      # 一時ファイルに生成
                      nix eval --raw --apply 'x: x.render x.options' .#genDocs > "$TEMP_FILE"
                      nix eval --raw --apply 'x: x.render x.hostsData' .#genSecretsDocs > "$SECRETS_TEMP_FILE"

                      # 日付行(2行目)を除いて比較。変わっていなければ何もしない
                      if ! diff <(sed '2d' CUSTOM_OPTIONS.md) <(sed '2d' "$TEMP_FILE") > /dev/null 2>&1; then
                        sed "s/__DATE_PLACEHOLDER__/$(date '+%Y-%m-%d %H:%M:%S')/" "$TEMP_FILE" > CUSTOM_OPTIONS.md
                        git add CUSTOM_OPTIONS.md
                      fi
                      if ! diff <(sed '2d' SECRETS.md 2>/dev/null) <(sed '2d' "$SECRETS_TEMP_FILE") > /dev/null 2>&1; then
                        sed "s/__DATE_PLACEHOLDER__/$(date '+%Y-%m-%d %H:%M:%S')/" "$SECRETS_TEMP_FILE" > SECRETS.md
                        git add SECRETS.md
                      fi

                      # 生成物にプレースホルダーが残っている場合は日付行だけ直す
                      for file in CUSTOM_OPTIONS.md SECRETS.md; do
                        if grep -q '__DATE_PLACEHOLDER__' "$file" 2>/dev/null; then
                          sed -i "2s/.*/Generated on $(date '+%Y-%m-%d %H:%M:%S')/" "$file"
                          git add "$file"
                        fi
                      done
                    '';
                  }
                }/bin/gen-docs";
              };
              gen-secrets = {
                enable = true;
                files = "\\.nix$";
                require_serial = true;
                name = "Regenerate secrets.nix";
                entry = "${
                  pkgs.writeShellApplication {
                    name = "gen-secrets";
                    runtimeInputs = with pkgs; [
                      nix
                      git
                      diffutils
                      coreutils
                      nixfmt
                    ];
                    text = ''
                      TEMP_FILE=$(mktemp)
                      trap 'rm -f "$TEMP_FILE"' EXIT

                      # nixfmtしないとdiffが生まれ続ける
                      nix eval --raw --apply 'x: x.render x.hostsData x.keys' .#genSecrets | nixfmt - > "$TEMP_FILE"

                      if ! diff -q secrets.nix "$TEMP_FILE" > /dev/null 2>&1; then
                        cp "$TEMP_FILE" secrets.nix
                        git add secrets.nix
                        echo "error: secrets.nix changed" >&2
                        exit 1
                      fi
                    '';
                  }
                }/bin/gen-secrets";
              };
            };
          };
        in
        {
          default = nixpkgs.legacyPackages.${system}.mkShell {
            inherit (hook) shellHook;
            packages = hook.enabledPackages;
          };
        }
      );
      nixosConfigurations = hostConfigs // {
        installer = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            {
              image.baseName = lib.mkForce "installer";
              networking.networkmanager.enable = lib.mkForce false;
              networking = {
                nameservers = [
                  "1.1.1.1"
                  "1.0.0.1"
                ];
                wireless = {
                  enable = true;
                  networks = {
                    # ここにWi-Fiのパスワードを入れる
                    # "ESSID".psk = "pwd";
                    # "eduroam".auth = ''
                    #   key_mgmt=WPA-EAP
                    #   eap=PEAP
                    #   phase2="auth=MSCHAPV2"
                    #   identity=""
                    #   password=""
                    # '';
                  };
                };
              };
              users.users.nixos.openssh.authorizedKeys.keys = [
                (lib.trim (builtins.readFile ./common/shell/ssh/id_ed25519.pub))
              ];
              services.avahi = {
                enable = true;
                settings = {
                  server = {
                    host-name = "installer";
                    # ipv6=true;だと、なぜかAレコードが帰ってこなくなる
                    use-ipv6 = false;
                  };
                  publish = {
                    disable-publishing = false;
                    disable-user-service-publishing = false;
                    publish-addresses = true;
                  };
                };
              };
              documentation = {
                enable = false;
                nixos.enable = false;
              };
            }
          ];
        };
      };

      # CUSTOM_OPTIONS.md の生成用:
      #   nix eval --raw --apply 'x: x.render x.options' .#genDocs
      # ドキュメント対象ホストは自動選択する (custom オプションのツリーは全ホスト共通)
      genDocs =
        let
          docHost = lib.head (lib.sort (a: b: a < b) (builtins.attrNames hosts));
        in
        {
          render = import ./gen-docs-render.nix { inherit lib; };
          options = hostConfigs.${docHost}.options.custom;
        };

      # secrets.nix の生成用:
      #   nix eval --raw --apply 'x: x.render x.hostsData x.keys' .#genSecrets
      genSecrets =
        let
          hostsData = lib.mapAttrs (_hostName: cfg: {
            system = lib.mapAttrsToList (_: s: s.file) cfg.config.age.secrets;
            home = lib.concatLists (
              lib.mapAttrsToList (
                user: hmCfg:
                lib.mapAttrsToList (_: s: {
                  inherit (s) file;
                  inherit user;
                }) hmCfg.age.secrets
              ) cfg.config.home-manager.users
            );
          }) hostConfigs;
        in
        {
          render = import ./gen-secrets-render.nix { inherit lib self; };
          inherit hostsData;
          keys = import ./keys.nix;
        };

      # SECRETS.md の生成用:
      #   nix eval --raw --apply 'x: x.render x.hostsData' .#genSecretsDocs
      genSecretsDocs = {
        render = import ./gen-secrets-docs-render.nix { inherit lib self; };
        hostsData = lib.mapAttrs (_hostName: cfg: {
          system = lib.mapAttrs (_name: secret: {
            inherit (secret)
              file
              path
              owner
              group
              mode
              ;
          }) cfg.config.age.secrets;
          home = lib.mapAttrs (
            _user: hm:
            lib.mapAttrs (
              name: secret:
              let
                runtimeName = secret.name or name;
                runtime = "${hm.age.secretsDir}/${runtimeName}";
              in
              {
                inherit (secret) file mode;
                inherit runtime;
                path = if secret.path == runtime then null else secret.path;
              }
            ) hm.age.secrets
          ) cfg.config.home-manager.users;
        }) hostConfigs;
      };
    };
}
