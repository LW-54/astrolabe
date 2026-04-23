{ config, pkgs, domain, ... }:

{
  # 1. Decrypt Zurg configuration
  sops.secrets."zurg_config" = {};

  # 2. Caddy Reverse Proxy
  services.caddy.virtualHosts = {
    "jellyfin.${domain}" = { extraConfig = "reverse_proxy 127.0.0.1:8096"; };
  };

  # 3. Restic Excludes (Protecting Backblaze from Real-Debrid)
  services.restic.backups.s3-main.exclude = [
    "/opt/docker-data/jellyfin/jellyfin-cache"
    "/opt/docker-data/jellyfin/jellyfin-config/metadata"
    "/opt/docker-data/jellyfin/mnt" # The massive Rclone FUSE mount
  ];
}
