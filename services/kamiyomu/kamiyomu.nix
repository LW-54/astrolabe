{ config, pkgs, domain, ... }:

{
  systemd.tmpfiles.rules = [
    "d /opt/docker-data/kamiyomu 0755 1000 1000 -"
    "d /opt/docker-data/kamiyomu/manga 0755 1000 1000 -"
    "d /opt/docker-data/kamiyomu/db 0755 1000 1000 -"
    "d /opt/docker-data/kamiyomu/agents 0755 1000 1000 -"
    "d /opt/docker-data/kamiyomu/logs 0755 1000 1000 -"

    "Z /opt/docker-data/kamiyomu - 1000 1000 -"
  ];

  services.caddy.virtualHosts = {
    "kamiyomu.${domain}" = { extraConfig = "reverse_proxy 127.0.0.1:8090"; };
  };
}
