{
  lib,
  mkEnabledOption,
  config,
  ...
}:
{
  options.custom.network.mycelium.enable = mkEnabledOption;

  config = lib.mkIf config.custom.network.mycelium.enable {
    services.mycelium = {
      enable = true;
      openFirewall = true;
    };
    environment.persistence."/persist".directories = [
      "/var/lib/private/mycelium"
    ];
    environment.shellAliases = {
      my-addr = "sudo mycelium -k /var/lib/mycelium/key.bin inspect";
    };
  };
}
