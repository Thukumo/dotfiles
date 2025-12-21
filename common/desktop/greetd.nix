{ config, lib, ... }:

{
  config = {
    services.greetd = {
      enable = true;
      settings = {
        default_session.user = config.users.users."tsukumo".name;
        initial_session.user = config.users.users."tsukumo".name;
      };
    };
  };
}
