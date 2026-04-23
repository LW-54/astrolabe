{ config, pkgs, domain, ... }:

{
  # The fully declarative permission map
  systemd.tmpfiles.rules = [
    # 1. Ensure the directories exist
    "d /opt/docker-data/seerr/config 0755 1000 1000 -"
    "d /opt/docker-data/seerr/bridge-data 0777 root root -"

    # 2. Forcefully and recursively apply ownership (Z) to override Docker
    "Z /opt/docker-data/seerr/config - 1000 1000 -"
    "Z /opt/docker-data/seerr/bridge-data - root root -"
  ];

  # Caddy Reverse Proxy
  services.caddy.virtualHosts = {
    "seerr.${domain}" = { extraConfig = "reverse_proxy 127.0.0.1:5055"; };
    "seerrbridge.${domain}" = { extraConfig = "reverse_proxy 127.0.0.1:3777"; };
  };
}
