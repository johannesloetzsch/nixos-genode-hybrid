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
 1      1 MB                  BBP              bios_grub
 2      1 GB     fat32        ESP              boot, esp
 3      25 GB    ext2         GENODE*
 4      *        ext4 or zfs  dom0
```

* Genode requires a gpt partition table
* Genode is persisted on a partition with the label `GENODE*`
* Booting via EFI and legacy bios is possible by having a ESP and a BBP partition

Declarative partitioning is provided by [`modules/genode/disk.nix`](../modules/genode/disk.nix)
(options `genode.disk.*`). To partition+format+mount use:

```bash
sudo nix run github:nix-community/disko/latest -- --mode destroy,format,mount --flake .#nixos-genode-hybrid
```

#### Luks, ZFS, …

The 4th partition is configured by `genode.disk.dom0`: `fs = "zfs"` (default) or `"ext4"`,
LUKS on/off (`dom0.luks`), optional swap zvol (`dom0.zfs.swap.size`).


### NixOS installation + Bootloader

This repository can be used as `/etc/nixos` of a NixOS to be newly installed. To do so, clone this repo into `/mnt/etc/nixos` after the target root-filesystem is mounted to `/mnt`.

If you want to regenerate a `hardware-configuration.nix`, run:

```bash
sudo nixos-generate-config --no-filesystems --root /mnt
```


Installation can be done via flake:

```bash
sudo nixos-install --flake /mnt/etc/nixos#nixos-genode-hybrid
## answer the prompt for a root password
sudo reboot  ## boot into your new installed NixOS
```


#### Bootloader config

Feel free to change `configuration.nix` to your needs. All required for the dualboot configuration is:

```nix
imports = [ ./genode-bootloader.nix ];
```


### Genode installation

Sculpt OS is installed by `genode.install` (`system.build.genodeInstall`, run by
`genode-install.service` on every boot):

* the GENODE partition is seeded **once** with `genode.install.latestVersion`.
  Once its `/boot` holds a system image, Sculpt OS owns that slot and replaces
  it on its own on-target updates. Use `genode.install.force = true` (or run
  `genode-install` with `--force`) to repair it.
* the pinned versions (`latestVersion` plus `genode.install.extraVersions`) are
  kept below `/sculpt/<version>/` on the ESP. Their `grub.cfg` is patched to
  those paths, and versions that are no longer pinned are removed.

The GRUB entries are `Genode (native)` (the slot managed by Sculpt OS),
`Genode (<version> - latest)` and one `Genode (<version>)` per pinned version.


### Configure Genode

If you want to run the existing linux on top of genode, you can use the config provided by this repo:

```bash
mount /dev/disk/by-partlabel/GENODE* $GENODE_MOUNTPOINT
cp -r ./genode/* $GENODE_MOUNTPOINT/
```

See [genode/README.md](./genode/README.md)
