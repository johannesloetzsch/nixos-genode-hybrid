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
    vbox = import ./vbox pkgs;
  in
  {

    ## The dualboot nixos host (bare metal nix or dualboot into the same machine on top of genode)
    nixosConfigurations."nixos-and-genode" = nixpkgs.legacyPackages.${system}.nixos [
      #disko.nixosModules.disko ./dualboot/disko.nix
      disko.nixosModules.disko ./dualboot/disko_luks_zfs.nix
      ./dualboot/configuration.nix
      ./nix/shared/opinionated/neo2-keyboard.nix
    ];


    ## VMs

    nixosModules."vm_example".imports = [
      nixos-generators.nixosModules.all-formats
      { virtualisation.diskSize = 20*1024; }  ## 20 GB
      ./nix/vm/example/configuration.nix
    ];
    nixosConfigurations."vm_example" = nixpkgs.legacyPackages.${system}.nixos [self.nixosModules."vm_example"];

    nixosModules."vm_test".imports = [
      nixos-generators.nixosModules.all-formats
      { virtualisation.diskSize = 20*1024; }  ## 20 GB
      ./nix/vm/test/configuration.nix
    ];
    nixosConfigurations."vm_test" = nixpkgs.legacyPackages.${system}.nixos [self.nixosModules."vm_example"];


    packages.${system} = {
      vm_example = vbox self.nixosConfigurations."vm_example".config;
      vm_test = vbox self.nixosConfigurations."vm_example".config;
    };

  };
}
