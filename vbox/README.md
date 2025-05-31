# nix build of vbox-vms for genode

This directory contains everything required for building virtual **machines from nixos-configurations**.

The packages defined at `default.nix` provide all files **for running on top of genode**:
* `hostname.vmdk`
* `machine.vbox6`
* `launcher/hostname`


## Example usage:

```sh
nix flake show
nix build ..#vm_example
ls result/example
```

> see [`flake.nix`](../flake.nix)
