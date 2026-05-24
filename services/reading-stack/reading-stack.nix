{ config, pkgs, domain, ... }:

{
  sops.secrets."reading-stack/kavita_api_key" = { };

  systemd.tmpfiles.rules = [
    "d /opt/docker-data/reading-stack/kavita 0755 1000 1000 -"
    "Z /opt/docker-data/reading-stack/kavita - 1000 1000 -"

    "d /opt/docker-data/reading-stack/suwayomi 0755 1000 1000 -"
    "Z /opt/docker-data/reading-stack/suwayomi - 1000 1000 -"

    "d /opt/docker-data/reading-stack/komf 0755 1000 1000 -"
    "Z /opt/docker-data/reading-stack/komf - 1000 1000 -"

    # Shared media folder and subdirectories
    "d /opt/docker-data/reading-stack/media 0777 root root -"
    "d /opt/docker-data/reading-stack/media/manga 0777 root root -"
    "d /opt/docker-data/reading-stack/media/comics 0777 root root -"
    "d /opt/docker-data/reading-stack/media/books 0777 root root -"
    "Z /opt/docker-data/reading-stack/media - root root -"
  ];

  # MergerFS: Flatten Suwayomi source-based folders into a single virtual root
  fileSystems."/opt/docker-data/reading-stack/media/manga_flat" = {
    fsType = "fuse.mergerfs";
    device = "/opt/docker-data/reading-stack/media/manga/*";
    options = [
      "cache.files=partial"
      "dropcacheonclose=true"
      "category.create=ff"
      "allow_other"
      "use_ino"
      "fsname=manga_flat"
    ];
  };

  # Caddy Reverse Proxy
  services.caddy.virtualHosts = {
    "kavita.${domain}" = { extraConfig = "reverse_proxy 127.0.0.1:5002"; };
    "suwayomi.${domain}" = { extraConfig = "reverse_proxy 127.0.0.1:8085"; };
  };

  # Exclude media from backups
  services.restic.backups.s3-main.exclude = [
    "/opt/docker-data/reading-stack/media"
  ];
}
