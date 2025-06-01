{ config, lib, pkgs, modulesPath, ... }:
{
  virtualisation.virtualbox.guest = {
    enable = true;  ## required for: <Display controller="VBoxSVGA"/> in machine.vbox6
    vboxsf = true;  ## allows: mount.vboxsf shared /mnt/
  };

  systemd.services."virtualbox".enable = false;  ## due to ERR_NOT_SUPPORTED


  ## Usage:
  #fileSystems."/genode" = {
  #  fsType = "vboxsf";
  #  device = "shared";
  #  noCheck = true;
  #  options = [ "nofail" ];
  #};
}
