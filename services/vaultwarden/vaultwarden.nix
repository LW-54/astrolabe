{ config, ... }:

{
  services.caddy.virtualHosts."vault.adje.app" = {# change soon
    extraConfig = ''
      reverse_proxy 127.0.0.1:8222
    '';
  };

  # services.restic.backups.s3-main.exclude = [ ];
}
