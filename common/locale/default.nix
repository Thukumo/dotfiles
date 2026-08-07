{
  myLib,
  config,
  lib,
  ...
}:

{
  time.timeZone = "Asia/Tokyo";

  i18n.defaultLocale = "ja_JP.UTF-8";

  console.keyMap = lib.mkDefault "jp106";
  services.xserver.xkb = {
    layout = lib.mkDefault "jp106";
    variant = "";
  };

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ja_JP.UTF-8";
    LC_IDENTIFICATION = "ja_JP.UTF-8";
    LC_MEASUREMENT = "ja_JP.UTF-8";
    LC_MONETARY = "ja_JP.UTF-8";
    LC_NAME = "ja_JP.UTF-8";
    LC_NUMERIC = "ja_JP.UTF-8";
    LC_PAPER = "ja_JP.UTF-8";
    LC_TELEPHONE = "ja_JP.UTF-8";
    LC_TIME = "ja_JP.UTF-8";
  };
  home-manager.users = myLib.mkForEachUsers config (_: true) (_: {
    xdg.configFile."user-dirs.locale" = {
      text = "en_US";
    };
  });
}
