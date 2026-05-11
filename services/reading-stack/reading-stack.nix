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

    # 1. Static YAML Structure (No secrets here, so it's perfectly safe)
    environment.etc."komf/application.yml" = {
    mode = "0644";
    text = ''
      kavita:
        baseUri: "http://kavita:5000"
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

    # 2. Secret Environment File (Injects only the API key)
    sops.templates."komf_env" = {
    path = "/run/komf_env";
    owner = "lw";
    content = ''
      KOMF_KAVITA_API_KEY=${config.sops.placeholder."reading-stack/kavita_api_key"}
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
