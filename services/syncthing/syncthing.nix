{ config, pkgs, domain, ... }:

let
  syncthingData = "/opt/docker-data/syncthing";
  syncRoot = "/home/lw/obsidian"; # Change to /home/lw if you want broader home sync.
in
{
  systemd.tmpfiles.rules = [
    "d ${syncthingData} 0755 1000 100 - -"
  ];

  systemd.services.syncthing = {
    description = "Syncthing container for Obsidian vault syncing";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" ];
    wants = [ "docker.service" ];

    serviceConfig = {
      Type = "simple";
      User = "root";
      Restart = "always";
      RestartSec = 10;
    };

    path = [ pkgs.docker-compose pkgs.coreutils ];

    script = ''
      mkdir -p "${syncthingData}"
      chown 1000:100 "${syncthingData}"
      cd /home/lw/astrolabe/services/syncthing
      exec docker-compose -f docker-compose.yml up
    '';
  };

  services.caddy.virtualHosts."syncthing.${domain}" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:8384
    '';
  };
}
