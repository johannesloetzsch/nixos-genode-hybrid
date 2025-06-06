{ config, lib, pkgs, ... }:

## Installs the bootloader required by genode.
## As e prerequisite, a „correct“ partitioning schema is required.
## For a dualboot setup, only one more script (`./install_sculpt.sh`) is required:
## https://github.com/johannesloetzsch/nixos-genode-hybrid?tab=readme-ov-file#genode-installation

{
  boot.loader.efi.canTouchEfiVariables = !config.boot.loader.grub.efiInstallAsRemovable;
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    devices = ["/dev/disk/by-partlabel/disk-main-ESP"];
    forceInstall = true;  # allow blocklists
    extraEntriesBeforeNixOS = true;
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


  ## To use a fido2-token for unlocking luks partitions `systemd-cryptenroll` should be available.
  ## This requires `boot.initrd.systemd.enable` (systemd as stage1).
  ## When using grub instead of systemd-boot, `boot.initrd.services.lvm.enable` must be set manually to support luks.

  boot.initrd = {
    systemd.enable = true;
    services.lvm.enable = config.boot.initrd.systemd.enable;
    luks.fido2Support = false;
    luks.devices."crypted_nixos" = {
      crypttabExtraOpts = [ "fido2-device=auto" ];
    };
  };
}
