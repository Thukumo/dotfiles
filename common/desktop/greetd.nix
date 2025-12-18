{ config, lib, ... }:

{
  config = lib.mkIf (config.custom.desktop.type != null) {
    services.greetd = {
      enable = true;
      settings = {
        default_session.user = config.users.users."tsukumo".name;
        initial_session.user = config.users.users."tsukumo".name;
      };
    };
  };
}
