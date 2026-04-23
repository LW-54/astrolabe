{ config, pkgs, domain, ... }:

{
  # Open the SeerrBridge ports through the firewall
  networking.firewall.allowedTCPPorts = [ 3777 8777 8778 ];

  # Declarative permissions for ALL required volumes
  systemd.tmpfiles.rules = [
    "d /opt/docker-data/seerr/config 0755 1000 1000 -"
    "d /opt/docker-data/seerr/bridge-data 0777 root root -"
    "d /opt/docker-data/seerr/bridge-logs 0777 root root -"
    "d /opt/docker-data/seerr/bridge-db 0777 root root -"

    "Z /opt/docker-data/seerr/config - 1000 1000 -"
    "Z /opt/docker-data/seerr/bridge-data - root root -"
    "Z /opt/docker-data/seerr/bridge-logs - root root -"
    "Z /opt/docker-data/seerr/bridge-db - root root -"
  ];

  # Caddy Reverse Proxy
  services.caddy.virtualHosts = {
    "seerr.${domain}" = { extraConfig = "reverse_proxy 127.0.0.1:5055"; };
    "seerrbridge.${domain}" = { extraConfig = "reverse_proxy 127.0.0.1:3777"; };
  };
}
