# Genode + NixOS

This repo provides tooling for:

* installing NixOS+Genode as a [dualboot](./dualboot) setup
  * The NixOS installation can run on bare metal or in a VM on top of Genode

* building [vbox](./vbox) based VMs


## Installation

The installing of NixOS is automated via disko+flake.nix; the step-by-step
procedure is in [docs/INSTALL.md](./docs/INSTALL.md); mounting an existing
installation is described in [docs/REINSTALL.md](./docs/REINSTALL.md).
The disk layout lives in [`modules/genode/disk.nix`](./modules/genode/disk.nix) (`genode.disk.*`).

Installing Sculpt OS is automated by [`modules/genode/install.nix`](./modules/genode/install.nix)
(`genode.install.*`); the GRUB entries live in [`modules/genode/boot.nix`](./modules/genode/boot.nix)
(`genode.boot.*`).

Pinned Sculpt OS releases are available as packages: `nix build .#sculpt-26_04`.

> See the detailed [Setup instructions](./dualboot/README.md)
