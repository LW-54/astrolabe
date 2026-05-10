{ config, pkgs, domain, ... }:

{
  # 1. Provide the secret path to SOPS
  sops.secrets."copyparty_env" = {
    # This will hold your main admin credentials or other environment variables if needed
  };

  # 2. Permissions for config folder
  systemd.tmpfiles.rules = [
    "d /opt/docker-data/copyparty/config 0755 1000 100 - -"
  ];

  # 3. Startup Script to create the users.txt file securely
  systemd.services.init-copyparty-users = {
    description = "Create Copyparty users.txt from SOPS secret";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "sops-nix.service" ];
    wants = [ "sops-nix.service" ];

    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = config.sops.secrets."copyparty_env".path;
      RemainAfterExit = true;
    };

    script = ''
      # Make sure the config directory exists
      mkdir -p /opt/docker-data/copyparty/config

      # Write the credentials to the file Copyparty expects
      # Format: username:password
      echo "admin:$COPYPARTY_PASSWORD" > /opt/docker-data/copyparty/config/users.txt

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
