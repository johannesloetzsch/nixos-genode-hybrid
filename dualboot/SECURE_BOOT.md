# Secure Boot

## Booting NixOS via Lanzaboote

> as described at [Quickstart](https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md)


## Booting Genode via Grub

1. Create a GPG-Keypair and export the public key

```sh
gpg --full-gen-key
KEYID=$(gpg --list-secret-keys --with-colons | grep '^sec' | cut -d':' -f5)
gpg --output /root/.gnupg/key.pub --export $KEYID
```

2. Install Grub
* Embed the pubkey for signature checking
* Use `sbctl` to sign the grub-efi-files

```sh
nix shell nixpkgs#grub2_efi.out
grub-install --removable --target=x86_64-efi --efi-directory=/boot/ --disable-shim-lock --pubkey=/root/.gnupg/key.pub --modules "pgp gcry_sha256 gcry_rsa"
sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI ; sbctl sign -s /boot/grub/x86_64-efi/grub.efi ; sbctl sign -s /boot/grub/x86_64-efi/core.efi
``` 

3. Sign all files loaded by grub

```sh 
for file in $(find /boot/grub/ -regextype posix-extended -regex '.*(\.cfg|\.lst|\.mod|grubenv)$'); do [[ -f "$file".sig ]] && rm "$file".sig; gpg --batch --detach-sign "$file"; done
for file in /genode/boot/grub/grub.cfg /genode/boot/bender /genode/boot/hypervisor /genode/boot/image.elf.gz; do [[ -f "$file".sig ]] && rm "$file".sig; gpg --batch --detach-sign "$file"; done
```


### Next Steps

* It would be worth to get rid of grub (since it is bloated) and start Genode directly from Lanzaboote…

* Before Genode is loading permanent customizations from the `GENODE*`-partition, a signature over this files should be checked…

* Secure boot for virtual machines…
