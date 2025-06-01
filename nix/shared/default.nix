{ config, lib, pkgs, ... }:
{
  imports = [
    ./opinionated/default_specialisation.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.etc."nixos-original".source = ../..;
}
