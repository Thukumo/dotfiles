let
  systemKeysAttr = {
    "mouse-3" = "age17f6qmquda9s8p2vegu0ynzmnyfhgqd9gxre4kngf87wagf5nvfeqas89m5";
    "yoga-book" = "age1u7eks62u4kj6y7v4hrcfumcvcwd3hlwkrw7su6l50x6ldreqpdnqsxjr2l";
    "16x-aurora" = "age1rq8eqfp4qsznzau3xla2ftq26d3wlhjk05l9c4tnwcpkj7ecxfqqfvtjad";
    "backup-pixel9a" = "age1akl70p6av6sjhuqa8wrr9ms5vn0jy6kgn5vh35c9m0jmg6hlrqtq9hp4cm";
    "thinkpadx13-nix" = "age1y3w68vz3g24mcaqu42vg76q0p9urnjekn42p60nlxnkh2zgdwqfsm4txkl";
  };
  homeKeysAttr = {
    "tsukumo" = "age1nzd7yc6dyg2m5ev35zdtydw8vprqx2qyt5pg6l5h786gqnge3vvsp6xxvh";
  };
  allKeys = (builtins.attrValues systemKeysAttr) ++ (builtins.attrValues homeKeysAttr);
  systemKeys = builtins.attrValues systemKeysAttr;
in
{
  # system
  "common/core/users/passwd_tsukumo.age".publicKeys = systemKeys;
  "common/core/users/home_manager_key.age".publicKeys = systemKeys;
  "common/network/wifi/pwds.age".publicKeys = systemKeys;
  "common/network/wifi/eduroam.age".publicKeys = systemKeys;
  "common/network/sras-vpn/sras-vpn.age".publicKeys = systemKeys;

  # tsukumo
  "common/shell/ssh/ssh-key_tsukumo.age".publicKeys = allKeys;
  "common/shell/git/gh_hosts_tsukumo.age".publicKeys = allKeys;
  "common/dev/opencode/auth_tsukumo.age".publicKeys = allKeys;
}
