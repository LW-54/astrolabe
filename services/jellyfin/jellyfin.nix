{ config, pkgs, domain, ... }:

{
  sops.secrets."zurg_config" = {};

  services.caddy.virtualHosts = {
    "jellyfin.${domain}" = { extraConfig = "reverse_proxy 127.0.0.1:8096"; };
  };

  # Create the unified media folders with universal access
  systemd.tmpfiles.rules = [
    "d /opt/docker-data/media 0777 root root -"
    "d /opt/docker-data/media/zurg 0777 root root -"
    "d /opt/docker-data/media/symlinks 0777 root root -"
  ];

  # Backup the symlinks, but exclude the massive raw Rclone mount
  services.restic.backups.s3-main.exclude = [
    "/opt/docker-data/jellyfin/jellyfin-cache"
    "/opt/docker-data/jellyfin/jellyfin-config/metadata"
    "/opt/docker-data/media/zurg"
  ];
}
