{
  description = "NixOS Flake";

  inputs = {
    git-hooks.url = "github:cachix/git-hooks.nix";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    nix-index-database.url = "github:nix-community/nix-index-database";

    affinity-nix.url = "github:mrshmllow/affinity-nix";

    nixvim.url = "github:nix-community/nixvim";

    gaze = {
      url = "github:GunduLabs/gaze";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri.url = "github:sodiboo/niri-flake";

    ragenix.url = "github:yaxitech/ragenix";
    nixos-anywhere.url = "github:nix-community/nixos-anywhere";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    lanzaboote.url = "github:nix-community/lanzaboote/v1.1.0";

    stylix.url = "github:nix-community/stylix/pull/2348/head";

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

    nowplaying.url = "github:Thukumo/nowplaying";

    # nixpkgs PR #526315 (ONLYOFFICE DesktopEditors: updates) の未マージ分。
    # programs.onlyoffice モジュールと extraFontPackages 対応パッケージを取り込む。
    onlyoffice-nixpkgs = {
      url = "github:emmanuelrosa/nixpkgs/156a0b2e84faa41250a1ff6141acf456cf5e91ff";
      flake = false;
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

        (import "${inputs.onlyoffice-nixpkgs}/nixos/modules/programs/onlyoffice.nix")

        {
          nixpkgs.overlays = [
            (final: _prev: {
              onlyoffice-desktopeditors = final.callPackage (
                inputs.onlyoffice-nixpkgs + "/pkgs/by-name/on/onlyoffice-desktopeditors/package.nix"
              ) { };
            })
          ];
        }
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

      systems = lib.unique (builtins.catAttrs "system" (builtins.attrValues hosts));
    in
    {
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
                name = "Generate custom options documentation";
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
                    # レンダリング本体は flake の genDocs 出力 (gen-docs-render.nix) にある
                    text = ''
                      TEMP_FILE=$(mktemp)
                      trap 'rm -f "$TEMP_FILE"' EXIT

                      # 一時ファイルに生成
                      nix eval --raw --apply 'x: x.render x.options' .#genDocs > "$TEMP_FILE"

                      # 日付行(2行目)を除いて比較。変わっていなければ何もしない
                      if ! diff <(sed '2d' CUSTOM_OPTIONS.md) <(sed '2d' "$TEMP_FILE") > /dev/null 2>&1; then
                        sed "s/__DATE_PLACEHOLDER__/$(date '+%Y-%m-%d %H:%M:%S')/" "$TEMP_FILE" > CUSTOM_OPTIONS.md
                        git add CUSTOM_OPTIONS.md
                      fi
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
      nixosConfigurations = lib.mapAttrs mkHost hosts // {
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
                hostName = "installer";
                # ipv6=true;だと、なぜかAレコードが帰ってこなくなる
                ipv6 = false;
                publish = {
                  enable = true;
                  userServices = true;
                  addresses = true;
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
          options = (lib.mapAttrs mkHost hosts).${docHost}.options.custom;
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
          }) (lib.mapAttrs mkHost hosts);
        in
        {
          render = import ./gen-secrets-render.nix { inherit lib self; };
          inherit hostsData;
          keys = import ./keys.nix;
        };
    };
}
