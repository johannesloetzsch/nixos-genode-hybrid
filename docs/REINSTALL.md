# Reinstall on an existing installation

Mounts an existing (or broken) installation and reinstalls on top of it.
This does **not** wipe anything: the Genode partition and `/boot` are untouched.

## 1. Mount the existing installation

`zpool import` refuses a pool whose recorded hostid differs from the current
system:

```
cannot import 'zroot': pool was previously in use from another system
```

On the live system `/etc/hostid` is a symlink into the store, so replace it:

```bash
rm /etc/hostid
printf '\xf6\x29\xd4\x57' > /etc/hostid   ## networking.hostId = "57d429f6", little-endian
```

Then let disko import the pool and mount everything:

```bash
nix run .#disko -- -m mount --flake .#nixos-genode-hybrid
```

Both lines are volatile — repeat them after every reboot of the live system.

`networking.hostId` is set in [`dualboot/configuration.nix`](../dualboot/configuration.nix).
`/etc/hostid` holds it little-endian, i.e. with the byte pairs reversed:
`57d429f6` → `\xf6\x29\xd4\x57`. Check with `hostid`.

Fallback without touching `/etc/hostid`:

```bash
## first try to unlock luks, but fail when importing zfs
nix run .#disko -- -m mount --flake .#nixos-genode-hybrid

## manual fix (using "-f")
zpool import -f -l -R /mnt zroot
nix run .#disko -- -m mount --flake .#nixos-genode-hybrid
```

## 2. Install

Continue with [INSTALL.md](./INSTALL.md), step 3.
