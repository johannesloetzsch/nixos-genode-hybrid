## GRUB entries for Genode.
##
## "Genode (native)" chainloads the system image that Sculpt manages itself:
## exactly one image below /boot of the GENODE partition (filesystem label
## GENODE). We seed that slot once (genode.install) and hand it over to Sculpt,
## which replaces /boot on its own on-target updates.
##
## The versions pinned by this repository live on the ESP below
## /sculpt/<version>/ and are chainloaded the same way. Their grub.cfg is
## patched at install time, so it never points into the Sculpt-managed slot.
##
## Requires genode.install, which owns the version selection.
{ config, lib, ... }:
let
  cfg = config.genode.boot;
  install = config.genode.install;

  espEntry = label: version: ''
    menuentry '${label}' {
      savedefault
      search --no-floppy --set=root --file /sculpt/${version}/grub/grub.cfg
      configfile /sculpt/${version}/grub/grub.cfg
    }
  '';

  entries =
    ''
      menuentry 'Genode (native)' {
        savedefault
        search --no-floppy --set=root --label GENODE --hint hd0,gpt3
        set gfxpayload="0x0x32"
        insmod gfxterm
        terminal_output gfxterm
        insmod gfx_background
        insmod png
        background_image -m center /boot/boot.png
        configfile /boot/grub/grub.cfg
      }
    ''
    + lib.optionalString install.useLatestVersion (
      espEntry "Genode (${install.latestVersion} - latest)" install.latestVersion
    )
    + lib.concatMapStrings (v: espEntry "Genode (${v})" v) install.extraVersions;
in
{
  options.genode.boot.enable = lib.mkEnableOption "GRUB entries for Genode";

  config = lib.mkIf cfg.enable {
    boot.loader.efi.canTouchEfiVariables = !config.boot.loader.grub.efiInstallAsRemovable;
    boot.loader.systemd-boot.enable = false;

    boot.loader.grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      devices = [ "/dev/disk/by-partlabel/ESP" ];
      forceInstall = true; # allow blocklists
      extraEntriesBeforeNixOS = true;
      extraEntries = entries;
      default = "saved"; # grub remembers the entry chosen at the last boot
      splashMode = "normal";
      configurationLimit = 10; # prevent /boot/kernels from running out of space
    };
  };
}
