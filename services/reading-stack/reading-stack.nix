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

  # Securely generate the Komf config with the secret key injected
  sops.templates."komf-application.yml" = {
    path = "/run/secrets/komf-application.yml";
    owner = "lw";
    content = ''
      server:
        port: 8085
      kavita:
        base-uri: "http://kavita:5000"
        api-key: "${config.sops.placeholder."reading-stack/kavita_api_key"}"
        event-listener:
          enabled: true
        metadata-update:
          default:
            aggregate: true
            series-thumbnails: true
            book-thumbnails: true
            series-metadata: true
            override-existing-covers: true
            update-mode: API
            post-processing:
              series-title: true
              order-books: true
      database:
        file: /config/database.sqlite
      metadata-providers:
        default-providers:
          manga-updates:
            enabled: true
            priority: 1
          ani-list:
            enabled: true
            priority: 2
          manga-dex:
            enabled: true
            priority: 3
      logging:
        level:
          root: INFO
          snd.komf: DEBUG

            priority: 3
    '';
  };

  # Caddy Reverse Proxy
  services.caddy.virtualHosts = {
    "kavita.${domain}" = { extraConfig = "reverse_proxy 127.0.0.1:5002"; };
    "suwayomi.${domain}" = { extraConfig = "reverse_proxy 127.0.0.1:8085"; };
    "komf.${domain}" = { extraConfig = "reverse_proxy 127.0.0.1:8086"; };
  };

  # Exclude media from backups
  services.restic.backups.s3-main.exclude = [
    "/opt/docker-data/reading-stack/media"
  ];
}
