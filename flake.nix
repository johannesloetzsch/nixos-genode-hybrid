{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    imports-nix = {
      url = "github:johannesloetzsch/imports.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, nixos-generators, imports-nix }:
  let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
    pkgs = nixpkgs.legacyPackages.${system};
    vbox = import ./vbox pkgs;
    sculpt = import ./modules/genode/sculpt { inherit pkgs; };
  in
  {

    nixosModules."genode-disk" = import ./modules/genode/disk.nix;
    nixosModules."genode-boot" = import ./modules/genode/boot.nix;
    nixosModules."genode-install" = import ./modules/genode/install.nix;

    ## The dualboot nixos host (bare metal nix or dualboot into the same machine on top of genode)
    nixosConfigurations."nixos-genode-hybrid" = nixpkgs.legacyPackages.${system}.nixos [
      disko.nixosModules.disko
      imports-nix.nixosModules.profiles.hardware_fixes
      self.nixosModules."genode-disk"
      self.nixosModules."genode-boot"
      self.nixosModules."genode-install"
      {
        genode.disk.enable = true;
        # fujitsu test disk: /dev/disk/by-id/ata-SAMSUNG_MZ7TY256HDHP-00000_S2YXNB0J406643
        genode.disk.device = "/dev/nvme0n1";
        genode.disk.esp.size = "1G";
        genode.disk.genode.size = "25G";
        genode.boot.enable = true;
        genode.install.enable = true;
        ## stable + oldstable, so both can be booted and compared
        genode.install.extraVersions = [ "26.04" "26.10" ];
      }
      ./dualboot/configuration.nix
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
      ## the disko CLI at the pinned input revision (same version as the module)
      disko = disko.packages.${system}.disko;
      vm_example = vbox self.nixosConfigurations."example".config;
      vm_test = vbox self.nixosConfigurations."test".config;
      vm_system-shell = vbox self.nixosConfigurations."system-shell".config;
    } // lib.mapAttrs' (
      name: drv: lib.nameValuePair "sculpt-${lib.replaceStrings [ "." ] [ "_" ] name}" drv
    ) sculpt;

  };
}
