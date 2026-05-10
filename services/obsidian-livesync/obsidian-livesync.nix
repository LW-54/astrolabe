{ config, pkgs, domain, ... }:

{
  # 1. Provide the secret path to SOPS
  sops.secrets."couchdb_env" = {
    owner = "lw";
  };

  # 2. Declaratively manage the CouchDB data directories and permissions
  systemd.tmpfiles.rules = [
    # Format: Type Path Mode User Group Age Argument
    # 'd' creates the directory if it doesn't exist.
    "d /opt/docker-data/obsidian-livesync/data 0755 5984 5984 - -"
    "d /opt/docker-data/obsidian-livesync/etc 0755 5984 5984 - -"
  ];

  # 3. Create a systemd service that initializes the databases
  # This service runs after Docker starts and waits for CouchDB to be responsive.
  systemd.services.init-couchdb = {
    description = "Initialize CouchDB system databases for Obsidian Live Sync";
    wantedBy = [ "multi-user.target" ];
    # Wait for the network and SOPS to be ready
    after = [ "network-online.target" "sops-nix.service" ];
    wants = [ "sops-nix.service" ];

    # Load the secrets into the environment of this script
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = config.sops.secrets."couchdb_env".path;
      RemainAfterExit = true; # Only run successfully once per boot
    };

    path = [ pkgs.curl pkgs.jq ];

    script = ''
      HOST="http://localhost:5984"

      # Wait for CouchDB to become available (up to 2 minutes)
      echo "Waiting for CouchDB to be ready on $HOST..."
      for i in {1..24}; do
        # We check for ANY response (even 401) to know the server is up.
        # Removing -f so it doesn't fail on 401 Unauthorized.
        if curl -s "$HOST/" > /dev/null; then
          echo "CouchDB is up!"
          break
        fi
        sleep 5
      done

      if ! curl -s -f "$HOST/" > /dev/null; then
        echo "CouchDB did not become ready in time. Exiting."
        exit 1
      fi

      AUTH="$COUCHDB_USER:$COUCHDB_PASSWORD"

      # Function to check if a DB exists and create it if not
      create_db() {
        local db_name=$1
        echo "Checking/Creating database: $db_name"
        # Try to create it. If it exists, CouchDB returns 412 Precondition Failed, which is fine.
        curl -s -X PUT "$HOST/$db_name" -u "$AUTH"
      }

      create_db "_users"
      create_db "_replicator"
      create_db "_global_changes"

      echo "CouchDB initialization complete."
    '';
  };

  # 4. Reverse Proxy for Obsidian Live Sync
  services.caddy.virtualHosts."sync.${domain}" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:5984
    '';
  };
}
