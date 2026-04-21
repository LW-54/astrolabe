{ config, pkgs, modulesPath, ... }:

let
  domain = "adje.app";
  sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOmdqlhZ0Pl74W0tNTu/L2iDziaIgafdo8LuTn2Ui/Cg";
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./services/vaultwarden/vaultwarden.nix
  ];

  networking.hostName = "astrolabe";
  system.stateVersion = "25.11";

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  # --- SOPS CONFIGURATION ---
  sops.defaultSopsFile = ./secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  # This tells the server where to look for the decryption key we pasted earlier
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  # Define the secrets that Restic needs
  sops.secrets."restic/env" = {};
  sops.secrets."restic/password" = {};

  # --- BACKBLAZE B2 RESTIC BACKUP ---
  services.restic.backups.s3-main = {
    # Replace <region> with your actual B2 region (e.g., us-west-004)
    repository = "s3:s3.eu-central-003.backblazeb2.com/cyclostyle-docker";

    # Sops injects the unencrypted strings directly into the service at runtime
    environmentFile = config.sops.secrets."restic/env".path;
    passwordFile = config.sops.secrets."restic/password".path;

    paths = [ "/opt/docker-data" ];

    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 12"
    ];

    timerConfig = {
      OnCalendar = "04:00";
      Persistent = true;
    };
  };

  # --- GIT REPO AUTOMATION ---
  system.activationScripts.cloneConfig = {
    text = ''
      if [ ! -d "/home/lw/astrolabe-config" ]; then
        ${pkgs.git}/bin/git clone https://github.com/LW-54/astrolabe.git /home/lw/astrolabe
        chown -R lw:users /home/lw/astrolabe
      fi
    '';
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  users.users.root.openssh.authorizedKeys.keys = [ "${sshKey} master-key" ];

  users.users.lw = {
    isNormalUser = true;
    description = "Leonard Wilson";
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [ "${sshKey} master-key" ];
  };

  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [
    lazydocker
    docker-compose
    git
    nano
    ttyd
  ];

  systemd.services.ttyd-web = {
    description = "ttyd Web Terminal";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      User = "lw";
      WorkingDirectory = "/home/lw";
      ExecStart = "${pkgs.ttyd}/bin/ttyd -i 127.0.0.1 -p 7681 -W ${pkgs.bashInteractive}/bin/bash";
      Restart = "always";
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  services.caddy = {
    enable = true;
    virtualHosts = {
      "ttyd.${domain}" = {
        extraConfig = ''
          basicauth / {
            admin $2a$14$vYmK17NeNy4sdgvOm6SAheSigD5Lnus70w8aJfQgLBceSG0hlVrPK
          }
          reverse_proxy localhost:7681
        '';
      };
      # Uptime Kuma and 2048 removed as requested.
    };
  };
}
