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
    repository = "s3:https://s3.eu-central-003.backblazeb2.com/cyclostyle-docker";

    # Sops injects the unencrypted strings directly into the service at runtime
    environmentFile = config.sops.secrets."restic/env".path;
    passwordFile = config.sops.secrets."restic/password".path;

    paths = [ "/opt/docker-data" ];

    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 12"
    ];

    initialize = true;

    timerConfig = {
      OnCalendar = "04:00";
      Persistent = true;
    };
  };

# --- GIT REPO AUTOMATION (NETWORK AWARE) ---
systemd.services.clone-astrolabe-repo = {
    description = "Clone Astrolabe Config Repository on First Boot";
    wantedBy = [ "multi-user.target" ];

    # 1. Timing: Wait for network AND for SOPS to finish decrypting your keys
    wants = [ "network-online.target" "sops-nix.service" ];
    after = [ "network-online.target" "sops-nix.service" ];

    path = [ pkgs.git pkgs.openssh ];

    serviceConfig = {
      Type = "oneshot";
      User = "lw";
      WorkingDirectory = "/home/lw";
      RemainAfterExit = true;
    };

    script = ''
      # 2. Wait up to 10 seconds for the SSH key to actually appear on disk
      for i in {1..10}; do
        if [ -f "/home/lw/.ssh/id_ed25519" ]; then break; fi
        sleep 1
      done

      if [ ! -d "/home/lw/astrolabe" ]; then
        # 3. The "Force Trust" flag: Tells SSH to ignore host checking ONLY for this command
        export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"
        git clone git@github.com:LW-54/astrolabe.git /home/lw/astrolabe
      fi
    '';
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  users.users.root.openssh.authorizedKeys.keys = [ "${sshKey} master-key" ];

  programs.ssh.knownHosts = {
    "github.com" = {
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    };
  };

  security.sudo.wheelNeedsPassword = false;

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

  sops.secrets."github_ssh_key" = {
      owner = "lw";
      path = "/home/lw/.ssh/id_ed25519";
      mode = "0400";
    };

  programs.git = {
      enable = true;
      config = {
        init.defaultBranch = "main";
        pull.rebase = false;
        user.name = "LW-54";
        user.email = "leonardwilsonb@gmail.com";
      };
    };

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
      "term.${domain}" = { #change back to ttyd after 23/04/2026
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
