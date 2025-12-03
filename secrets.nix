let
  keys = {
    thinkpadx13-gen1 = "age1y3w68vz3g24mcaqu42vg76q0p9urnjekn42p60nlxnkh2zgdwqfsm4txkl";
  };
  allKeys = builtins.attrValues keys;
in {
  "secrets/ssh-key.age".publicKeys = allKeys;
  "secrets/passwd_tsukumo.age".publicKeys = allKeys;
  "secrets/gh_hosts.age".publicKeys = allKeys;
}
