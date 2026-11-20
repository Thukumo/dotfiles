{
  # Keep the session on disk before the battery runs out.
  systemd.sleep.settings.Sleep.HibernateDelaySec = "30min";
  services.logind.settings.Login.HandleLidSwitch = "suspend-then-hibernate";
  services.logind.settings.Login.HandleSuspendKey = "suspend-then-hibernate";
}
