{ config, lib, ... }:

{
  # options.custom.desktop = {
  #   defaultUser = lib.mkOption {
  #     type = lib.types.str;
  #   };
  # };
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
