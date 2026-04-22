# 🛰️ Astrolabe Infrastructure

Declarative NixOS configuration for `adje.app`, featuring encrypted secrets via **sops-nix** and automated off-site backups via **Restic**.

## 🚀 Deployment Guide

### 1. Prepare Secrets (Local Machine)
Since the server drive is wiped, you must provide the `age` key so `nixos-anywhere` can inject it. This allows the server to decrypt secrets (like SSH keys and B2 credentials) on the first boot.

```bash
# Create the secret directory
mkdir -p /tmp/extra-files/var/lib/sops-nix/

# Copy your age key into the staging area
cp ~/.config/sops/age/keys.txt /tmp/extra-files/var/lib/sops-nix/key.txt
```

### 2. Provision the OS
Run this from your local machine to wipe the VPS and install the configuration.

```bash
nix run github:nix-community/nixos-anywhere -- \
  -i ~/.ssh/id_ed25519_vps \
  --extra-files /tmp/extra-files \
  --build-on local \
  --flake .#astrolabe \
  root@adje.app
```

### 3. Restore Persistent Data
Once the server is up, SSH in as `lw` and restore the Docker volumes from Backblaze B2.

```bash
sudo restic-s3-main restore latest --target /
```

## 🛠️ Maintenance Commands

* **Apply Changes:** `sudo nixos-rebuild switch --flake .#astrolabe`
* **Manual Backup:** `sudo systemctl start restic-backups-s3-main.service`
* **Check Backups:** `sudo restic-s3-main snapshots`
* **Update Flake:** `nix flake update`
