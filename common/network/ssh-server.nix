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
      hostKeys = [
        {
          path = "/persist/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
        {
          path = "/persist/etc/ssh/ssh_host_rsa_key";
          type = "rsa";
        }
      ];
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    services.fail2ban.enable = true;
    # sshd writes the host keys (and their .pub files) directly into /persist.
    custom.impermanence.gc.keep = [ "/persist/etc/ssh" ];
    systemd.tmpfiles.rules = [
      "d /persist/etc/ssh 0755 root root -"
    ];
  };
}
