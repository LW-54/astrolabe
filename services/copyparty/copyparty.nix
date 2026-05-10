{ config, pkgs, domain, ... }:

{
  # 1. Define the secret that will hold the account list (user:pass)
  sops.secrets."copyparty_users" = {
    owner = "lw";
  };

  # 2. Permissions for config folder
  systemd.tmpfiles.rules = [
    "d /opt/docker-data/copyparty/config 0755 1000 100 - -"
  ];

  # 3. Startup Script to generate the copyparty.conf file
  systemd.services.init-copyparty-config = {
    description = "Generate Copyparty copyparty.conf from SOPS secret";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "sops-nix.service" ];
    wants = [ "sops-nix.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      # Make sure the config directory exists
      mkdir -p /opt/docker-data/copyparty/config

      # Create the config file with the [accounts] header
      echo "[accounts]" > /opt/docker-data/copyparty/config/copyparty.conf

      # Append the user list from the SOPS secret
      cat ${config.sops.secrets."copyparty_users".path} >> /opt/docker-data/copyparty/config/copyparty.conf

      # Ensure correct permissions
      chown 1000:100 /opt/docker-data/copyparty/config/copyparty.conf
      chmod 600 /opt/docker-data/copyparty/config/copyparty.conf
    '';
  };

  # 4. Reverse Proxy for Copyparty
  services.caddy.virtualHosts."copyparty.${domain}" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:3923
    '';
  };
}
