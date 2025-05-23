{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko }:
  {
    nixosConfigurations.nixos-and-genode = nixpkgs.legacyPackages.x86_64-linux.nixos [
      #disko.nixosModules.disko ./disko.nix
      disko.nixosModules.disko ./disko_luks_zfs.nix
      ./configuration.nix
    ];
  };
}
