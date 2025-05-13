{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.2";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko, lanzaboote }:
  {
    nixosConfigurations.nixos-and-genode = nixpkgs.legacyPackages.x86_64-linux.nixos [
      disko.nixosModules.disko ./disko.nix
      lanzaboote.nixosModules.lanzaboote
      ./configuration.nix
    ];
  };
}
