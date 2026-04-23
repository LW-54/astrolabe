{ config, pkgs, domain, ... }:

{
  # The Nix Way to fix permissions: Create the folder securely before Docker starts
  systemd.tmpfiles.rules = [
    "d /opt/docker-data/seerr/config 0755 1000 1000 -"
  ];

  # Caddy Reverse Proxy (Updated to the correct 3777 port)
  services.caddy.virtualHosts = {
    "seerr.${domain}" = { extraConfig = "reverse_proxy 127.0.0.1:5055"; };
    "seerrbridge.${domain}" = { extraConfig = "reverse_proxy 127.0.0.1:3777"; };
  };
}
