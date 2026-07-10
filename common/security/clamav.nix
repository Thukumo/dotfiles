{
  lib,
  myLib,
  config,
  ...
}:
let
  myCfg = config.custom.security.clamav;
in
{
  options.custom.security.clamav = {
    enable = myLib.mkEnabledOption;
    realtime = {
      enable = myLib.mkEnabledOption;
    };
  };
  config = {
    nixpkgs.overlays = lib.mkIf myCfg.enable [
      (final: prev: {
        clamav = prev.clamav.overrideAttrs (oldAttrs: {
          patches = (oldAttrs.patches or [ ]) ++ [
            # Hash table collision list corruption fix.
            # Waiting for this Nixpkgs PR to be merged: https://github.com/NixOS/nixpkgs/pull/537628
            (final.fetchpatch {
              url = "https://github.com/Cisco-Talos/clamav/pull/1712.patch";
              hash = "sha256-9E8V/ibF3u27OUBNYUX651Mzw0zDIKl7wR2L5AambuU=";
            })
          ];
          # Remove FTS_XDEV from clamonacc's directory traversal options.
          # WHY: Under NixOS Impermanence, directories under /home (like Documents, Steam, etc.) are bind mounts
          # on different virtual devices. FTS_XDEV prevents ClamAV from descending into these mount points during traversal.
          # However, ClamAV's pre-order children retrieval still reads and lists their contents, creating a mismatch
          # (children are listed but never inserted into the watched paths hash table), which crashes clamonacc on startup.
          # Disabling FTS_XDEV allows ClamAV to cross mount boundaries safely and register all paths correctly.
          postPatch = (oldAttrs.postPatch or "") + ''
            substituteInPlace clamonacc/inotif/hash.c --replace "FTS_PHYSICAL | FTS_XDEV" "FTS_PHYSICAL"
          '';
        });
      })
    ];

    services.clamav = lib.mkIf myCfg.enable {
      scanner.enable = true;
      updater.enable = true;
      daemon = {
        enable = true;
        settings = {
          OnAccessIncludePath = "/home";
          OnAccessExcludeUname = "clamav";
          OnAccessPrevention = "yes";
        };
      };
      clamonacc.enable = myCfg.realtime.enable;
    };
    environment.persistence."/persist".directories = lib.mkIf myCfg.enable [
      {
        directory = "/var/lib/clamav";
        user = "clamav";
        group = "clamav";
        mode = "755";
      }
    ];
  };
}
