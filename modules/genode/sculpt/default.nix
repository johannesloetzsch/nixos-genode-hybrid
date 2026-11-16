## Pinned Sculpt OS releases as verified, extracted upstream boot trees.
##
##   nix build .#sculpt-26_04
##   result/boot/{bender,hypervisor,image.elf.gz,grub/…}
{ pkgs }:
let
  versions = import ./versions.nix;
  verify = import ./verify.nix { inherit pkgs; };
  extract = import ./extract.nix { inherit pkgs; };
in
builtins.mapAttrs (
  name: data:
  extract {
    inherit name;
    image = verify {
      inherit name;
      inherit (data) imgUrl imgSha256 sigSha256;
      sigUrl = data.imgUrl + ".asc";
    };
  }
) versions
