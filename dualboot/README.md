# nixos + genode

This setup supports to run:
* [x] NixOS VMs within a Genode host
* [x] Genode VMs within a NixOS host


## Features

* [x] **declarative partitioning** with [disko](https://github.com/nix-community/disko)
  * [x] *optional* luks-encryption (fido2)
  * [x] *optional* zfs (with specialised bootloader entries per snapshot/clone)
* [x] **reproducible installation** of NixOS+Bootloader with `flake.nix`
* [x] **Sculpt OS (dual boot)** installation from NixOS (or other linux)
  * [x] *optional* Neo2-Keyboard-Layout
* [x] Run the native linux system inside of **Genode hypervisor** (vbox6-block)
  * [x] *optional* access to genode-partition (vboxsf)
  * [x] *optional* SSH from outside via `nic_router` into linux

## Details

The instructions assume you are booted into a NixOS-Live-System or another system with Nix.

### Partitioning

To achieve our goals, a disk layout similar to the setup described by [jschlatow at genodians](https://genodians.org/jschlatow/2021-04-23-start-existing-linux-from-sculpt) is used:

```
Partition Table: gpt

Number  Size     File system  Name             Flags
 1      1 MB                  disk-main-BBP    bios_grub
 2      512 MB   fat32        disk-main-ESP    boot, esp
 3      100 GB   ext2         GENODE*
 4      *        ext4         disk-main-NIXOS
```

* Genode requires a gpt partition table
* Genode is persisted on a partition with the label `GENODE*`
* Booting via EFI and legacy bios is possible by having a ESP and a BBP partition

Declarative partitioning is provided by `./disko.nix` based on [hybrid.nix](https://raw.githubusercontent.com/nix-community/disko/refs/heads/master/example/hybrid.nix). To partition+format+mount use:

```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount disko.nix
nix shell nixpkgs#parted
sudo parted /dev/${DISK} name 3 GENODE*
```

The last command is required to change the partition label from `disk-main-GENODE` to `GENODE*`

#### Luks, ZFS, …

The 4th partition can be partitioned however you want.

This repo contins an example on using Luks-encryption and ZFS: [`./disko_luks_zfs.nix`](./disko_luks_zfs.nix)


### NixOS installation + Bootloader

This repository can be used as `/etc/nixos` of a NixOS to be newly installed. To do so, clone this repo into `/mnt/etc/nixos` after the target root-filesystem is mounted to `/mnt`.

If you want to regenerate a `hardware-configuration.nix`, run:

```bash
sudo nixos-generate-config --no-filesystems --root /mnt
```


Installation can be done via flake:

```bash
sudo nixos-install --flake /mnt/etc/nixos#nixos-and-genode
## answer the prompt for a root password
sudo reboot  ## boot into your new installed NixOS
```


#### Bootloader config

Feel free to change `configuration.nix` to your needs. All required for the dualboot configuration is:

```nix
imports = [ ./genode-bootloader.nix ];
```


### Genode installation

To download, extract and copy Sculpt OS into the partition labeled `GENODE*` from any running linux run:

```bash
nix shell nixpkgs#p7zip
sudo ./install_sculpt.sh
```


### Configure Genode

If you want to run the existing linux on top of genode, you can use the config provided by this repo:

```bash
mount /dev/disk/by-partlabel/GENODE* $GENODE_MOUNTPOINT
cp -r ./genode/* $GENODE_MOUNTPOINT/
```

See [genode/README.md](./genode/README.md)
