{ config, lib, pkgs, ... }:

{
  ## Neo2 Keyboard layout

  services.xserver.xkb = {
    layout = "de";
    variant = "neo";
  };

  ## use xkb.options in tty.
  console.useXkbConfig = true;
}
