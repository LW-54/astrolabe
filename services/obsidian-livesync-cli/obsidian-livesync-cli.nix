{ config, pkgs, domain, ... }:

let
  vaultPath = "/home/lw/obsidian/Memex";
  cliData = "/opt/docker-data/obsidian-livesync-cli/data";
  cliSettings = "${cliData}/settings.json";
in
{
  systemd.tmpfiles.rules = [
    # Ensure the local CLI database/storage path exists with the right ownership.
    "d /opt/docker-data/obsidian-livesync-cli/data 0755 1000 100 - -"
  ];

  systemd.services.obsidian-livesync-cli = {
    description = "Obsidian LiveSync CLI daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" ];
    wants = [ "docker.service" ];

    serviceConfig = {
      Type = "simple";
      User = "root";
      Restart = "always";
      RestartSec = 10;
      EnvironmentFile = config.sops.secrets."couchdb_env".path;
    };

    path = [ pkgs.docker-compose pkgs.coreutils ];

    script = ''
      mkdir -p "${cliData}"

      if [ ! -f "${cliSettings}" ]; then
          cat > "${cliSettings}" <<EOF
      {
        "couchDB_URI": "http://localhost:5984",
        "couchDB_USER": "$COUCHDB_USER",
        "couchDB_PASSWORD": "$COUCHDB_PASSWORD",
  "couchDB_DBNAME": "obsidian-livesync",
  "liveSync": true,
  "syncOnSave": true,
  "syncOnStart": true,
  "encrypt": false,
  "usePluginSync": false,
  "isConfigured": true
}
EOF
      fi

      cd /home/lw/astrolabe/services/obsidian-livesync-cli
      exec docker-compose -f docker-compose.yml up
    '';
  };
}
