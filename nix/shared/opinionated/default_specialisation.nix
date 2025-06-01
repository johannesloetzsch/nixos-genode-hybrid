{ config, lib, pkgs, ... }:
{
  specialisation."opinionated".configuration = {
    imports = [ ./default.nix ];
  };
}
