# GENERATED FILE - do not edit manually.
# Generated from keys.nix and the age.secrets declarations in the host configurations.
# Regenerate with:
#   nix eval --raw --apply 'x: x.render x.hostsData x.keys' .#genSecrets
let
  keys = import ./keys.nix;
in
{
  # common/core/users/passwd_tsukumo.age
  #   referenced by: 16x-aurora, mouse-3, thinkpadx13-nix, yoga-book
  "common/core/users/passwd_tsukumo.age".publicKeys = [
    keys.systemKeys."16x-aurora"
    keys.systemKeys."mouse-3"
    keys.systemKeys."thinkpadx13-nix"
    keys.systemKeys."yoga-book"
    keys.systemKeys."backup-pixel9a"
  ];

  # common/desktop/services/nowplaying/nowplaying-token.age
  #   referenced by: tsukumo@16x-aurora, tsukumo@mouse-3, tsukumo@thinkpadx13-nix, tsukumo@yoga-book
  "common/desktop/services/nowplaying/nowplaying-token.age".publicKeys = [
    keys.homeKeys."tsukumo"."16x-aurora"
    keys.homeKeys."tsukumo"."mouse-3"
    keys.homeKeys."tsukumo"."thinkpadx13-nix"
    keys.homeKeys."tsukumo"."yoga-book"
    keys.systemKeys."backup-pixel9a"
  ];

  # common/dev/opencode/auth_tsukumo.age
  #   referenced by: tsukumo@16x-aurora, tsukumo@mouse-3, tsukumo@thinkpadx13-nix
  "common/dev/opencode/auth_tsukumo.age".publicKeys = [
    keys.homeKeys."tsukumo"."16x-aurora"
    keys.homeKeys."tsukumo"."mouse-3"
    keys.homeKeys."tsukumo"."thinkpadx13-nix"
    keys.systemKeys."backup-pixel9a"
  ];

  # common/network/sras-vpn/sras-vpn.age
  #   referenced by: 16x-aurora, mouse-3, thinkpadx13-nix, yoga-book
  "common/network/sras-vpn/sras-vpn.age".publicKeys = [
    keys.systemKeys."16x-aurora"
    keys.systemKeys."mouse-3"
    keys.systemKeys."thinkpadx13-nix"
    keys.systemKeys."yoga-book"
    keys.systemKeys."backup-pixel9a"
  ];

  # common/network/wifi/eduroam.age
  #   referenced by: 16x-aurora, thinkpadx13-nix, yoga-book
  "common/network/wifi/eduroam.age".publicKeys = [
    keys.systemKeys."16x-aurora"
    keys.systemKeys."thinkpadx13-nix"
    keys.systemKeys."yoga-book"
    keys.systemKeys."backup-pixel9a"
  ];

  # common/network/wifi/pwds.age
  #   referenced by: 16x-aurora, thinkpadx13-nix, yoga-book
  "common/network/wifi/pwds.age".publicKeys = [
    keys.systemKeys."16x-aurora"
    keys.systemKeys."thinkpadx13-nix"
    keys.systemKeys."yoga-book"
    keys.systemKeys."backup-pixel9a"
  ];

  # common/shell/git/gh_hosts_tsukumo.age
  #   referenced by: tsukumo@16x-aurora, tsukumo@mouse-3, tsukumo@thinkpadx13-nix, tsukumo@yoga-book
  "common/shell/git/gh_hosts_tsukumo.age".publicKeys = [
    keys.homeKeys."tsukumo"."16x-aurora"
    keys.homeKeys."tsukumo"."mouse-3"
    keys.homeKeys."tsukumo"."thinkpadx13-nix"
    keys.homeKeys."tsukumo"."yoga-book"
    keys.systemKeys."backup-pixel9a"
  ];

  # common/shell/ssh/ssh-key_tsukumo.age
  #   referenced by: tsukumo@16x-aurora, tsukumo@mouse-3, tsukumo@thinkpadx13-nix, tsukumo@yoga-book
  "common/shell/ssh/ssh-key_tsukumo.age".publicKeys = [
    keys.homeKeys."tsukumo"."16x-aurora"
    keys.homeKeys."tsukumo"."mouse-3"
    keys.homeKeys."tsukumo"."thinkpadx13-nix"
    keys.homeKeys."tsukumo"."yoga-book"
    keys.systemKeys."backup-pixel9a"
  ];

  # hosts/mouse-3/cloudflared-nowplaying-credentials.age
  #   referenced by: mouse-3
  "hosts/mouse-3/cloudflared-nowplaying-credentials.age".publicKeys = [
    keys.systemKeys."mouse-3"
    keys.systemKeys."backup-pixel9a"
  ];

}
