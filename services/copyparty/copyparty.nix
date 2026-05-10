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

  # 3. Startup Script to copy the SOPS secret directly to users.txt
  systemd.services.init-copyparty-users = {
    description = "Copy SOPS secret to Copyparty users.txt";
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

      # Copy the contents of the SOPS secret, but STRIP all newlines
      # to prevent Copyparty's -a parser from crashing on blank lines.
      tr -d '\n' < ${config.sops.secrets."copyparty_users".path} > /opt/docker-data/copyparty/config/users.txt

      # Ensure correct permissions
      chown 1000:100 /opt/docker-data/copyparty/config/users.txt
      chmod 600 /opt/docker-data/copyparty/config/users.txt
    '';
  };

  # 4. Reverse Proxy for Copyparty
  services.caddy.virtualHosts."copyparty.${domain}" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:3923
    '';
  };
}
