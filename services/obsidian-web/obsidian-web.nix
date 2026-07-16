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

    # 3. Dynamic Permission Watchdog
  systemd.services.obsidian-permission-watchdog = {
    description = "Dynamic geometric-backoff permission repair for Obsidian vault";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" ];

    serviceConfig = {
      Type = "simple";
      User = "root";
      Restart = "always";
      RestartSec = "10";
    };

    path = [ pkgs.findutils pkgs.coreutils ];

    script = ''
      VAULT="/home/lw/obsidian"
      DELAY=60
      MAX_DELAY=14400 # 4 hours (4 * 60 * 60 seconds)

      mkdir -p $VAULT

      while true; do
        # Extremely fast check: exits immediately upon finding the FIRST bad file/dir
        BAD_FILES=$(find $VAULT \( ! -uid 1000 -o ! -gid 100 \) -print -quit)

        if [ -n "$BAD_FILES" ]; then
          echo "Permission mismatch detected. Running full repair..."
          
          # Repair ownership
          chown -R 1000:100 $VAULT
          
          # Repair directories (2775 = rwxrwsr-x, which enforces group inheritance)
          find $VAULT -type d -exec chmod 2775 {} +
          
          # Repair files (664 = rw-rw-r--)
          find $VAULT -type f -exec chmod 664 {} +

          echo "Repair complete. Resetting delay to 1 minute."
          DELAY=60
        else
          # No issues found. Double the delay, capped at MAX_DELAY
          DELAY=$(( DELAY * 2 ))
          if [ $DELAY -gt $MAX_DELAY ]; then
            DELAY=$MAX_DELAY
          fi
        fi

        sleep $DELAY
      done
    '';
  };

}
