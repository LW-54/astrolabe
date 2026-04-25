{ config, pkgs, domain, ... }:

{
  sops.secrets."zurg_config" = {};

  services.caddy.virtualHosts = {
    "jellyfin.${domain}" = { extraConfig = "reverse_proxy 127.0.0.1:8096"; };
  };

  # Generate the official smart webhook script on the host
  environment.etc."zurg_webhook.sh" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      # Formats Zurg's changed folder names into a JSON payload for cli_debrid
      PATHS=""
      for arg in "$@"; do
        PATHS="$PATHS\"$arg\","
      done
      PATHS=''${PATHS%,} # Remove trailing comma

      curl -s -X POST "https://clidebrid.adje.app/api/webhook/rclone" \
        -H "Content-Type: application/json" \
        -d "{\"data\": [$PATHS]}"
    '';
  };

  systemd.tmpfiles.rules = [
    "d /opt/docker-data/media 0777 root root -"
    "d /opt/docker-data/media/zurg 0777 root root -"
    "d /opt/docker-data/media/symlinks 0777 root root -"
  ];

  services.restic.backups.s3-main.exclude = [
    "/opt/docker-data/jellyfin/jellyfin-cache"
    "/opt/docker-data/jellyfin/jellyfin-config/metadata"
    "/opt/docker-data/media/zurg"
  ];
}
