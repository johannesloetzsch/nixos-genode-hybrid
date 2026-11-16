# Installation

End-to-end procedure for installing this setup on a single disk.
It **destroys** the target disk.

## Prerequisites

Nix with flakes:

```bash
export NIX_CONFIG='experimental-features = nix-command flakes'
```

## 1. Pick the target disk

The host definition lives in [`flake.nix`](../flake.nix):

```nix
genode.disk.device = "/dev/nvme0n1";   ## your disk
genode.disk.esp.size = "1G";
genode.disk.genode.size = "25G";
```

The rest of the layout comes from the module defaults: GPT with BBP, ESP,
`GENODE` and the remaining space as LUKS + ZFS for NixOS.

## 2. Partition, format, mount

Already installed? Mount it instead of wiping it — see
[REINSTALL.md](./REINSTALL.md).

> **Warning: this wipes the target disk.** `--mode destroy` deletes every
> partition on `genode.disk.device` — there is no undo. Check the device path
> from step 1 before you run it.

```bash
nix run .#disko -- --mode destroy,format,mount --flake .#nixos-genode-hybrid
```

`disko` asks for the LUKS passphrase interactively and mounts the target below
`/mnt`.

> `.#nixos-genode-hybrid` only sees files tracked by git. While new modules are
> still uncommitted, use `--flake path:$PWD#nixos-genode-hybrid` instead.

## 3. Install

```bash
nixos-install --flake .#nixos-genode-hybrid
```

The installer asks for the **root** password only. The first user (`user`) is
created without a password and cannot log in yet — see step 5.

## 4. First boot

* GRUB offers `Genode (native)`, `Genode (<version> - latest)` and NixOS.
* `genode-install.service` seeds the `GENODE` partition once and puts the
  pinned Sculpt versions below `/boot/sculpt/<version>/`:

```bash
systemctl status genode-install
ls /boot/sculpt/
grep multiboot2 /boot/sculpt/*/grub/grub.cfg   ## paths must start with /sculpt/
```

`Genode (<version> - latest)` only works after this service ran once; before
that its `/sculpt/…` path does not exist.

To seed without booting first (the service then skips the seed), run it inside
the installed system:

```bash
nixos-enter --root /mnt -c 'genode-install'
```

## 5. Set the password of the first user

Before the first boot:

```bash
nixos-enter --root /mnt -c 'passwd user'
```

If you forgot it: boot, switch to a free console with `Ctrl+Alt+F1`, log in as
`root`, run `passwd user`, then return to the graphical session with
`Ctrl+Alt+F7`.
