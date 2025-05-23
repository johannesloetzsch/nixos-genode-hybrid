{ config, lib, pkgs, ... }:

## Installs the bootloader required by genode.
## As e prerequisite, a „correct“ partitioning schema is required.
## For a dualboot setup, only one more script (`./install_sculpt.sh`) is required:
## https://github.com/johannesloetzsch/nixos-genode-hybrid?tab=readme-ov-file#genode-installation

{
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    devices = ["/dev/disk/by-partlabel/disk-main-ESP"];
    forceInstall = true;  # allow blocklists
    extraEntries = ''
      menuentry 'Genode' {
        savedefault
        set root=(hd0,gpt3)
        #search --set=root --label GENODE --hint hd0,gpt3
        set gfxpayload="0x0x32"
        insmod gfxterm
        terminal_output gfxterm
        insmod gfx_background
        insmod png
        background_image -m center /boot/boot.png
        configfile /boot/grub/grub.cfg
      }
    '';
    default = "saved";
    #splashImage = "/boot/background_genode.png";
    splashMode = "normal";
    configurationLimit = 10;  ## prevent /boot/kernels from running out of space
  };
}
