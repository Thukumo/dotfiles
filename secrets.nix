let
  keys = {
    thinkpadx13-gen1 = "age1y3w68vz3g24mcaqu42vg76q0p9urnjekn42p60nlxnkh2zgdwqfsm4txkl";
    backup-pixel9a = "age1akl70p6av6sjhuqa8wrr9ms5vn0jy6kgn5vh35c9m0jmg6hlrqtq9hp4cm";
  };
  allKeys = builtins.attrValues keys;
in {
  "secrets/ssh-key_tsukumo.age".publicKeys = allKeys;
  "secrets/passwd_tsukumo.age".publicKeys = allKeys;
  "secrets/gh_hosts_tsukumo.age".publicKeys = allKeys;
}

