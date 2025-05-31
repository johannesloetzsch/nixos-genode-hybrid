{pkgs, config}:
pkgs.stdenv.mkDerivation rec {
  name = "machine.vbox6";
  buildInputs = with pkgs; [ gnused ];
  buildCommand = ''
    mkdir -p $out
    sed 's/@@name@@/${config.networking.hostName}/g' ${./templates/machine.vbox6} > $out/machine.vbox6
  '';
}
