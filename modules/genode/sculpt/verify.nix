## Verifies a Sculpt OS release image against its detached signature.
## The signing key is pinned in this repository (./pubkey.asc,
## fingerprint 6566 131D 7AD8 13BA 544B A91B DA43 9C67 842B 4F25).
{ pkgs }:
{
  name,
  imgUrl,
  imgSha256,
  sigUrl,
  sigSha256,
}:
let
  img = pkgs.fetchurl {
    url = imgUrl;
    sha256 = imgSha256;
  };
  sig = pkgs.fetchurl {
    url = sigUrl;
    sha256 = sigSha256;
  };
in
pkgs.runCommand "sculpt-${name}-verified" { nativeBuildInputs = [ pkgs.gnupg ]; } ''
  set -euo pipefail

  export GNUPGHOME=$TMPDIR/gnupg
  mkdir -m 700 $GNUPGHOME

  gpg --batch --dearmor < ${./pubkey.asc} > keyring.gpg
  gpgv --keyring ./keyring.gpg ${sig} ${img}

  mkdir $out
  ln -s ${img} $out/sculpt.img
''
