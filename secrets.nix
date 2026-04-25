let
  systemKeysAttr = {
    "16x-aurora" = "age1rq8eqfp4qsznzau3xla2ftq26d3wlhjk05l9c4tnwcpkj7ecxfqqfvtjad";
    "gf65" = "age1pw34dvuy3k0pmpas7ej4sy2d8mutvp724a5afylfr0rcknndpyrscdzeh8";
    "backup-pixel9a" = "age1akl70p6av6sjhuqa8wrr9ms5vn0jy6kgn5vh35c9m0jmg6hlrqtq9hp4cm";
    "thinkpadx13-gen1" = "age1y3w68vz3g24mcaqu42vg76q0p9urnjekn42p60nlxnkh2zgdwqfsm4txkl";
  };
  homeKeysAttr = {
    "tsukumo" = "age1nzd7yc6dyg2m5ev35zdtydw8vprqx2qyt5pg6l5h786gqnge3vvsp6xxvh";
  };
  allKeys = (builtins.attrValues systemKeysAttr) ++ (builtins.attrValues homeKeysAttr);
  systemKeys = builtins.attrValues systemKeysAttr;
  globalSecrets = "common/secrets/secrets";
  tsukumoSecrets = "common/secrets/home-ragenix/secrets";
in
{
  "${globalSecrets}/passwd_tsukumo.age".publicKeys = systemKeys;
  "${globalSecrets}/home_manager_key.age".publicKeys = systemKeys;
  "${globalSecrets}/wifi/pwds.age".publicKeys = systemKeys;
  "${globalSecrets}/wifi/eduroam.age".publicKeys = systemKeys;

  "${tsukumoSecrets}/ssh-key_tsukumo.age".publicKeys = allKeys;
  "${tsukumoSecrets}/gh_hosts_tsukumo.age".publicKeys = allKeys;
}
