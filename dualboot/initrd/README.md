# Initrd

Nix uses `dracut` for generating initial ramdisks.

To unpack an initrd for inspection, use:
```sh
nix shell nixpkgs#dracut
mkdir /tmp/initrd; cd /tmp/initrd

lsinitrd --unpack /boot/kernels/${YOUR_INITRD}-initrd
```


## Hooks
### if boot.initrd.systemd.enable == false

The relevant files of `stage1` are:
```sh
ls nix/store/*stage-1-init.sh nix/store/*initrd-fsinfo
```

We can hook into it, using:
```nix
boot.initrd.preLVMCommands  ## after udev
boot.initrd.postResumeCommands  ## after luksOpen, before mounting (via fsinfo)
```


### if boot.initrd.systemd.enable == true

We may want:
```nix
boot.initrd.services.lvm.enable = true;
```

Otherwise Luks doesn't work
