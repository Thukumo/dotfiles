{ ... }:

{
  age = {
    secrets = {
      "passwd_tsukumo".file = ../secrets/passwd_tsukumo.age;
      "home-manager_key" = {
        file = ../secrets/home_manager_key.age;
        owner = "tsukumo";
        mode = "400";
      };
    };
  };
}
