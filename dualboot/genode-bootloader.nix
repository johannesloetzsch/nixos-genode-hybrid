{ config, lib, pkgs, ... }:

## Initrd configuration for the dualboot host. The bootloader itself
## (GRUB, ramp, Genode entries) lives in ../modules/genode/boot.nix.

{
  ## To use a fido2-token for unlocking luks partitions `systemd-cryptenroll` should be available.
  ## This requires `boot.initrd.systemd.enable` (systemd as stage1).
  ## When using grub instead of systemd-boot, `boot.initrd.services.lvm.enable` must be set manually to support luks.

  boot.initrd = {
    systemd.enable = true;
    services.lvm.enable = config.boot.initrd.systemd.enable;
    luks.fido2Support = false;
#    luks.devices."crypted_nixos" = { crypttabExtraOpts = [ "fido2-device=auto" ]; };
  };
}
