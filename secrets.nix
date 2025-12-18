let
  keys = {
    home_manager_key = "age1nzd7yc6dyg2m5ev35zdtydw8vprqx2qyt5pg6l5h786gqnge3vvsp6xxvh";
    backup-pixel9a = "age1akl70p6av6sjhuqa8wrr9ms5vn0jy6kgn5vh35c9m0jmg6hlrqtq9hp4cm";
    thinkpadx13-gen1 = "age1y3w68vz3g24mcaqu42vg76q0p9urnjekn42p60nlxnkh2zgdwqfsm4txkl";
    gf65 = "age10e3ker8ga8dnp7urmygff4rh0vtmkxhp23j0ltsw7jsyezwdsgvqeqddh8";
  };
  allKeys = builtins.attrValues keys;
in
{
  "common/feats/secrets/secrets/passwd_tsukumo.age".publicKeys = allKeys;
  "common/feats/secrets/secrets/home_manager_key.age".publicKeys = allKeys;
  "common/feats/secrets/home-ragenix/secrets/ssh-key_tsukumo.age".publicKeys = allKeys;
  "common/feats/secrets/home-ragenix/secrets/gh_hosts_tsukumo.age".publicKeys = allKeys;
}
