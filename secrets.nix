let
  keys = {
    home_manager_key = "age1nzd7yc6dyg2m5ev35zdtydw8vprqx2qyt5pg6l5h786gqnge3vvsp6xxvh";
    backup-pixel9a = "age1akl70p6av6sjhuqa8wrr9ms5vn0jy6kgn5vh35c9m0jmg6hlrqtq9hp4cm";
    thinkpadx13-gen1 = "age1y3w68vz3g24mcaqu42vg76q0p9urnjekn42p60nlxnkh2zgdwqfsm4txkl";
    gf65 = "age1f893n55rx9xx797ut9zm2k7ty72mk2l24tuar88sygm0tw29n9wsmx3wvv";
  };
  allKeys = builtins.attrValues keys;
in
{
  "common/secrets/secrets/passwd_tsukumo.age".publicKeys = allKeys;
  "common/secrets/secrets/home_manager_key.age".publicKeys = allKeys;
  "common/secrets/home-ragenix/secrets/ssh-key_tsukumo.age".publicKeys = allKeys;
  "common/secrets/home-ragenix/secrets/gh_hosts_tsukumo.age".publicKeys = allKeys;
}
