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
      CONF="/opt/docker-data/copyparty/config/copyparty.conf"
      mkdir -p /opt/docker-data/copyparty/config

      # Build the configuration file
      echo "[global]" > $CONF
      echo "e2d" >> $CONF
      echo "e2t" >> $CONF
      echo "" >> $CONF

      echo "[accounts]" >> $CONF
      cat ${config.sops.secrets."copyparty_users".path} >> $CONF
      echo "" >> $CONF

      echo "[/]" >> $CONF
      echo "/home/lw" >> $CONF
      echo "accs:" >> $CONF
      echo "  A: admin" >> $CONF

      # Ensure correct permissions
      chown 1000:100 $CONF
      chmod 600 $CONF
    '';  };

  # 4. Reverse Proxy for Copyparty
  services.caddy.virtualHosts."copyparty.${domain}" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:3923
    '';
  };
}
