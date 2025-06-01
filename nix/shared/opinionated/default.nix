{ config, lib, pkgs, ... }:
{
  imports = [
    ./neo2-keyboard.nix
  ];

  time.timeZone = "Europe/Amsterdam";
}
