{
  desktopLib,
  ...
}:
{
  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.librewolf.enable or false) (
      user:
      { lib, ... }:
      {
        programs.librewolf = {
          enable = true;
          languagePacks = [ "ja" ];
          policies.ExtensionSettings = lib.mapAttrs (_id: slug: {
            installation_mode = "normal_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
          }) (user.custom.desktop.apps.librewolf.extensions or { });
        };
        home.persistence."/persist".directories = [
          ".config/librewolf"
        ];
      }
    );
  };
}
