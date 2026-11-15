{
  # Public read-only Attic cache. The signing key is managed by Attic and
  # imported on first boot from hosts/mouse-3/secrets/attic-signing-key.age.
  domain = "cache.tsukumo.f5.si";
  port = 8081;
  publicKey = "cache.tsukumo.f5.si-1:uGJLdX9UfothroWiYCXKq0mm9YniQrPNOnquDOfJrS0=";
  substituter = "https://cache.tsukumo.f5.si/dotfiles";

  # cache.nixos.org has priority 40; keep Attic below it so the narrow uplink
  # prefers the official cache whenever a path exists there.
  priority = 50;

  # Attic skips uploading paths that upstream caches already provide.
  upstreamCacheKeyNames = [
    "cache.nixos.org-1"
    "cache.nixos-cuda.org"
    "tsukumo.cachix.org-1"
    "niri.cachix.org-1"
    "winapps.cachix.org-1"
  ];
}
