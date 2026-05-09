{
  lib,
  config,
  ...
}:
{
  options.custom.network.ssh-server = {
    enable = lib.mkEnableOption "OpenSSH Server";
  };

  config = lib.mkIf config.custom.network.ssh-server.enable {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    services.fail2ban.enable = true;
  };
}
