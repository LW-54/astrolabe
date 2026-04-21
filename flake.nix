{
  description = "Tier 1: Minimal OVH Infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # ADDED: The sops-nix input
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko, sops-nix, ... }@inputs: {
    nixosConfigurations.astrolabe = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        disko.nixosModules.disko
        # ADDED: Inject sops into the module tree
        sops-nix.nixosModules.sops
        ./disk-config.nix
        ./configuration.nix
      ];
    };
  };
}
