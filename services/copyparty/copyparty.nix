{ config, pkgs, domain, ... }:

{
  sops.secrets."copyparty_users" = {
    owner = "lw";
  };

  systemd.tmpfiles.rules = [
    "d /opt/docker-data/copyparty/config 0755 1000 100 - -"
  ];

  systemd.services.init-copyparty-config = {
    description = "Generate Copyparty config from SOPS secret";
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

      # 1. Global Settings
      echo "[global]" > $CONF
      echo "e2d" >> $CONF
      echo "e2t" >> $CONF
      echo "" >> $CONF

      # 2. Accounts (Sourced securely from SOPS)
      echo "[accounts]" >> $CONF
      cat ${config.sops.secrets."copyparty_users".path} >> $CONF
      echo "" >> $CONF

      # 3. Volume and Permissions
      echo "[/]" >> $CONF
      echo "/home/lw" >> $CONF
      echo "accs:" >> $CONF
      echo "  A: admin" >> $CONF

      chown 1000:100 $CONF
      chmod 600 $CONF
    '';
  };

  services.caddy.virtualHosts."copyparty.${domain}" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:3923
    '';
  };
}
