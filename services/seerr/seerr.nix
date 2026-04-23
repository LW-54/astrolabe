{ config, pkgs, domain, ... }:

{
  # Decrypt SeerrBridge environment variables
  sops.secrets."seerrbridge_env" = {
      owner = "lw";
    };

  # Caddy Reverse Proxy
  services.caddy.virtualHosts = {
    "seerr.${domain}" = { extraConfig = "reverse_proxy 127.0.0.1:5055"; };
    "bridge.${domain}" = { extraConfig = "reverse_proxy 127.0.0.1:8777"; };
  };
}
