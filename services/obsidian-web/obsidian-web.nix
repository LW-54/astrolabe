{ config, pkgs, domain, ... }:

{
  # 1. Permissions and Directories
  systemd.tmpfiles.rules = [
    "d /opt/docker-data/obsidian-web/config 0755 1000 100 - -"
    "d /home/lw/obsidian 0755 1000 100 - -"
  ];

  # 2. Reverse Proxy with Basic Auth Hash
  services.caddy.virtualHosts."obsidian.${domain}" = {
    extraConfig = ''
      basicauth / {
        admin $2a$14$vYmK17NeNy4sdgvOm6SAheSigD5Lnus70w8aJfQgLBceSG0hlVrPK
      }
      reverse_proxy 127.0.0.1:7211
    '';
  };
}
