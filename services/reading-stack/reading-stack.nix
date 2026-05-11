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
  # Strictly following the official example structure: https://github.com/Snd-R/komf
  sops.templates."komf-application.yml" = {
    path = "/run/komf_app.yml";
    owner = "lw";
    content = ''
      kavita:
        baseUri: "http://kavita:5000"
        apiKey: "${config.sops.placeholder."reading-stack/kavita_api_key"}"
        eventListener:
          enabled: true
        metadataUpdate:
          default:
            libraryType: "MANGA"
            updateModes: [ API ]
            aggregate: true
            bookCovers: true
            seriesCovers: true
            overrideExistingCovers: true
            lockCovers: true
            postProcessing:
              seriesTitle: true
              orderBooks: true

      database:
        file: /config/database.sqlite

      metadataProviders:
        defaultProviders:
          mangaUpdates:
            priority: 10
            enabled: true
          aniList:
            priority: 20
            enabled: true

      server:
        port: 8085

      logLevel: DEBUG
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
