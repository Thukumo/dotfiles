{ ... }:

{
  services.chrony = {
    enable = true;
    initstepslew.threshold = 1.0;
  };
  environment.persistence."/persist".directories = [
    "/var/lib/chrony"
  ];
}
