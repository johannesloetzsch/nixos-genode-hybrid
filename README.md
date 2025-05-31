# Genode + NixOS

This repo provides tooling for:

* installing NixOS+Genode as a [dualboot](./dualboot) setup
  * The NixOS installation can run on bare metal or in a VM on top of Genode

* building [vbox](./vbox) based VMs


## Installation

The installing of NixOS is automated via disko+flake.nix.

Installing Sculpt OS is possible via a shell [script](./dualboot/install_sculpt.sh).

> See the detailed [Setup instructions](./dualboot/README.md)
