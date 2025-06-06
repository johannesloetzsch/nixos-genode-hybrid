# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./genode-bootloader.nix

      ../nix/shared/default.nix
      ../nix/shared/vboxsf.nix
    ];


  networking.hostName = "nixos-and-genode";  ## Define your hostname. Use the same name in flake.nix
  networking.hostId = "57d429f6";  ## Required for zfs

  networking.networkmanager.enable = true;  ## Easiest to use and most distros use this by default.

  environment.systemPackages = with pkgs; [
    tmux git
    wget
    htop atop
    chromium
  ];

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  virtualisation.virtualbox.host.enable = true;
  boot.blacklistedKernelModules = [ "kvm_intel" ];

  fileSystems."/genode" = {
    fsType = "vboxsf";
    device = "shared";
    noCheck = true;
    options = [ "nofail" ];
  };


  specialisation."root2".configuration = {
    boot.kernelParams = [ "fsinfo.root=zroot/root2" ];
  };


  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager.mate.enable = true;
  };


  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."user" = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "vboxusers" ];
    packages = with pkgs; [];
  };

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "prohibit-password";  ## authorized_keys only


  system.stateVersion = "25.05";
}
