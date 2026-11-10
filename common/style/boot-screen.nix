{
  lib,
  ...
}:
{
  options.custom.style.bootScreen = lib.mkOption {
    type = lib.types.nullOr (
      lib.types.enum [
        "bootvine"
        "plymouth"
      ]
    );
    default = "bootvine";
    example = "plymouth";
    description = ''
      Which program draws the boot screen:

      - `"bootvine"`: systemd dependency tree on tty12
      - `"plymouth"`: graphical splash
      - `null`: no custom boot screen
    '';
  };
}
