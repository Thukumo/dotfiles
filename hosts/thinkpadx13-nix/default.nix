{ antigravity-nix, ... }:

{
  system = "x86_64-linux";

  specialArgs = { };

  modules = [
    ./configuration.nix
    ./hardware-configuration.nix
    {
      home-manager.users."tsukumo" =
        { config, ... }:
        {
          home.packages = [
            antigravity-nix.packages.x86_64-linux.default
          ];
          home.persistence."/persist${config.home.homeDirectory}".directories = [
            ".antigravity"
            ".config/Antigravity"
          ];
        };
    }
  ];
}
