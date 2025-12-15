{ lib, config, ... }:

{
  # この値に関わらずniriでfuzzel使ってる
  options.custom.desktop.launcher = {
    type = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "fuzzel" ]);
      default = lib.mapNullable (_: "fuzzel") config.custom.desktop.type;
    };
  };
  config = lib.mkMerge [
    (lib.mkIf (config.custom.desktop.launcher.type == "fuzzel") {
      home-manager.users."tsukumo".programs.fuzzel = {
        enable = true;
        settings = {
          main = {
            use-bold = "yes";
            dpi-aware = "no";
            font = "Adwaita Mono Nerd Font:size=18";
          };
        };
      };
    })
  ];
}
