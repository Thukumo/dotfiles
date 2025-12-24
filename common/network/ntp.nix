{ ... }:

{
  services.chrony = {
    enable = true;
  };
  environment.persistence."/persist".directories = [
    "/var/lib/chrony"
  ];
}
