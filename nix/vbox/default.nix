pkgs:
  config:
  pkgs.stdenv.mkDerivation rec {
    name = "vmdk+vbox6+launcher";
    buildInputs = with pkgs; [ virtualbox gnugrep ];
    buildCommand = ''
      out=$out/${config.networking.hostName}
      mkdir -p $out/launcher

      VMDK="$out/${config.networking.hostName}.vmdk"
      VBoxManage clonehd ${config.formats.vmware}/*.vmdk $VMDK --resize ${toString config.virtualisation.diskSize}
      UUID=$(VBoxManage internalcommands dumphdinfo $VMDK | grep -oP '(?<=uuidCreation=\{)[^}]+')

      sed "s/@@uuid@@/$UUID/g" ${import ./vbox.nix {inherit pkgs config;}}/machine.vbox6 > $out/machine.vbox6

      cp ${import ./launcher.nix {inherit pkgs config;}}/launcher $out/launcher/vbox_${config.networking.hostName}
    '';
  }
