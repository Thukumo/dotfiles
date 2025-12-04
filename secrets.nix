let
  keys = {
    thinkpadx13-gen1 = "age1y3w68vz3g24mcaqu42vg76q0p9urnjekn42p60nlxnkh2zgdwqfsm4txkl";
    backup-pixel9a = "age1akl70p6av6sjhuqa8wrr9ms5vn0jy6kgn5vh35c9m0jmg6hlrqtq9hp4cm";
    home_mamager_key = "age1nzd7yc6dyg2m5ev35zdtydw8vprqx2qyt5pg6l5h786gqnge3vvsp6xxvh";
  };
  allKeys = builtins.attrValues keys;
in {
  "secrets/passwd_tsukumo.age".publicKeys = allKeys;
  "secrets/home_manager_key.age".publicKeys = allKeys;
  "home-manager/ragenix/secrets/ssh-key_tsukumo.age".publicKeys = allKeys;
  "home-manager/ragenix/secrets/gh_hosts_tsukumo.age".publicKeys = allKeys;
}
