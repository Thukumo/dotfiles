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

  i18n.extraLocaleSettings = lib.genAttrs [
    "LC_ADDRESS"
    "LC_IDENTIFICATION"
    "LC_MEASUREMENT"
    "LC_MONETARY"
    "LC_NAME"
    "LC_NUMERIC"
    "LC_PAPER"
    "LC_TELEPHONE"
    "LC_TIME"
  ] (_: "ja_JP.UTF-8");
  home-manager.users = myLib.mkForEachUsers config (_: true) (_: {
    xdg.configFile."user-dirs.locale" = {
      text = "en_US";
    };
  });
}
