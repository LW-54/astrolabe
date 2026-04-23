{ config, pkgs, domain, ... }:

{
  services.caddy.virtualHosts."vaultwarden.${domain}" = {# change soon
    extraConfig = ''
      reverse_proxy 127.0.0.1:8222
    '';
  };

  # services.restic.backups.s3-main.exclude = [ ];
}
