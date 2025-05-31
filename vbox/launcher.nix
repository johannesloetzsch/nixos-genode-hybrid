{pkgs, config}:
pkgs.stdenv.mkDerivation rec {
  name = "launcher";
  buildInputs = with pkgs; [ gnused ];
  buildCommand = ''
    mkdir -p $out
    sed 's/@@name@@/${config.networking.hostName}/g' ${./templates/launcher} > $out/launcher
  '';
}
