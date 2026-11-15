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

    nixosModules."genode-disk" = import ./modules/genode/disk.nix;

    ## The dualboot nixos host (bare metal nix or dualboot into the same machine on top of genode)
    nixosConfigurations."nixos-and-genode" = nixpkgs.legacyPackages.${system}.nixos [
      disko.nixosModules.disko
      self.nixosModules."genode-disk"
      {
        genode.disk.enable = true;
        # fujitsu test disk: /dev/disk/by-id/ata-SAMSUNG_MZ7TY256HDHP-00000_S2YXNB0J406643
        genode.disk.device = "/dev/nvme0n1";
        genode.disk.esp.size = "512M";
        genode.disk.genode.size = "100G";
        genode.disk.dom0.luks.name = "crypted_nixos";
        genode.disk.dom0.luks.passwordFile = "/tmp/secret.key";
      }
      ./dualboot/configuration.nix
      ./nix/shared/opinionated/neo2-keyboard.nix
    ];


    ## VMs

    nixosModules."example".imports = [
      nixos-generators.nixosModules.all-formats
      { virtualisation.diskSize = 20*1024; }  ## 20 GB
      ./nix/vm/example/configuration.nix
    ];
    nixosConfigurations."example" = nixpkgs.legacyPackages.${system}.nixos [self.nixosModules."example"];

    nixosModules."test".imports = [
      nixos-generators.nixosModules.all-formats
      { virtualisation.diskSize = 20*1024; }
      ./nix/vm/test/configuration.nix
    ];
    nixosConfigurations."test" = nixpkgs.legacyPackages.${system}.nixos [self.nixosModules."test"];

    nixosModules."system-shell".imports = [
      nixos-generators.nixosModules.all-formats
      { virtualisation.diskSize = 20*1024; }
      ./nix/vm/system-shell/configuration.nix
    ];
    nixosConfigurations."system-shell" = nixpkgs.legacyPackages.${system}.nixos [self.nixosModules."system-shell"];


    packages.${system} = {
      vm_example = vbox self.nixosConfigurations."example".config;
      vm_test = vbox self.nixosConfigurations."test".config;
      vm_system-shell = vbox self.nixosConfigurations."system-shell".config;
    };

  };
}
