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


  ## fallback in case mbr-pt.vmdk doesn't contain the expected partlabels
  boot.initrd = {
    preLVMCommands = lib.mkBefore ''
      echo @@@ preLVMCommands @@@
      [ -e /dev/sda4 ] && ! [ -e /dev/disk/by-partlabel/disk-main-luks ] && ln -s /dev/sda4 /dev/disk/by-partlabel/disk-main-luks && ls -l /dev/disk/by-partlabel/disk-main-luks
      [ -e /dev/sda2 ] && ! [ -e /dev/disk/by-partlabel/disk-main-ESP ]  && ln -s /dev/sda2 /dev/disk/by-partlabel/disk-main-ESP  && ls -l /dev/disk/by-partlabel/disk-main-ESP
      echo @@@ preLVMCommands @@@
    '';
    postResumeCommands = lib.mkAfter ''
      echo @@@ postResumeCommands @@@
      ## We change the zfs-clone to be used as / by modifying initrd-fsinfo depending on /proc/cmdline
      cat /proc/cmdline

      for o in $(cat /proc/cmdline); do
        case $o in
          fsinfo.root=*)
            set -- $(IFS==; echo $o)
            DEV=$2
            DEV_ORIG="zroot/root"  ## TODO for now it is hardcoded, take it from fsinfo

            sed -i "s@^$DEV_ORIG\$@$DEV@" /nix/store/*initrd-fsinfo
            ;;
        esac
      done

      cat /nix/store/*initrd-fsinfo
      echo @@@ postResumeCommands @@@
    '';
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
