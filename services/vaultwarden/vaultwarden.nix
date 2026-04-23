{ config, ... }:

{
  services.caddy.virtualHosts."vaultwarden.adje.app" = {# change soon
    extraConfig = ''
      reverse_proxy 127.0.0.1:8222
    '';
  };

  # services.restic.backups.s3-main.exclude = [ ];
}
