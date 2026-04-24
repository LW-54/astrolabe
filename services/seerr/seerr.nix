{ config, pkgs, domain, ... }:

{
  # Open the required ports through the firewall
  networking.firewall.allowedTCPPorts = [ 5055 5000 ];

  # Declarative permissions to prevent Docker from locking the folders
  systemd.tmpfiles.rules = [
    "d /opt/docker-data/seerr/config 0755 1000 1000 -"
    "Z /opt/docker-data/seerr/config - 1000 1000 -"

    # CLI Debrid requires several subfolders. Granting 777 to the parent allows
    # the container to safely map its volumes.
    "d /opt/docker-data/seerr/cli_debrid 0777 root root -"
    "Z /opt/docker-data/seerr/cli_debrid - root root -"
  ];

  # Caddy Reverse Proxy
  services.caddy.virtualHosts = {
    "seerr.${domain}" = { extraConfig = "reverse_proxy 127.0.0.1:5055"; };
    "clidebrid.${domain}" = { extraConfig = "reverse_proxy 127.0.0.1:5000"; };
  };
}
