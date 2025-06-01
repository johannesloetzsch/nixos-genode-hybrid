# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../../dualboot/genode-bootloader.nix  ## we need legacy boot
    "${toString modulesPath}/virtualisation/vmware-image.nix"

    ../../shared/default.nix
    ../../shared/login/autologin-tty.nix
    ../../shared/vboxsf.nix
  ];

  networking.hostName = "system-shell";

  fileSystems."/genode" = {
    fsType = "vboxsf";
    device = "shared";
    noCheck = true;
  };

  environment.systemPackages = with pkgs; [
    tmux git
  ];

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  system.stateVersion = "25.11";  ## https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
}

