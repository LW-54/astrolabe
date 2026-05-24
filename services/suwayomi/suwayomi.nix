{ config, pkgs, domain, ... }:

{
  systemd.tmpfiles.rules = [
    "d /opt/docker-data/suwayomi 0777 root root -"
  ];

  services.caddy.virtualHosts."suwayomi.${domain}" = {
    extraConfig = "reverse_proxy 127.0.0.1:8085";
  };

  # Exclude the heavy downloads sub-folder from backups
  services.restic.backups.s3-main.exclude = [
    "/opt/docker-data/suwayomi/downloads"
  ];
}
