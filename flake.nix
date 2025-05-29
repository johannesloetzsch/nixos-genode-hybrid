{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, nixos-generators }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    vbox = import ./nix/vbox pkgs;
  in
  {
    nixosConfigurations."nixos-and-genode" = nixpkgs.legacyPackages.${system}.nixos [
      #disko.nixosModules.disko ./disko.nix
      disko.nixosModules.disko ./disko_luks_zfs.nix
      ./configuration.nix
      ./nix/opinionated/neo2-keyboard.nix
    ];

    nixosModules."vm".imports = [
      nixos-generators.nixosModules.all-formats
      { virtualisation.diskSize = 20*1024; }  ## 20GB
      ./vm/configuration.nix
    ];
    nixosConfigurations."vm" = nixpkgs.legacyPackages.${system}.nixos [self.nixosModules."vm"];
    packages.${system}."vm" = vbox self.nixosConfigurations."vm".config;
  };
}
