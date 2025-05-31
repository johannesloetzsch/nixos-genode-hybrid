{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            BBP = {  # BIOS boot partition
              size = "1M";
              type = "EF02";  # for grub MBR
            };
            ESP = {  # EFI system partition
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ] ++ [ "nofail" ];  ## nofail should only be used when mbr-pt.vmdk doesn't contain the expected partlabels
              };
            };
            GENODE = {
              size = "100G";
              content = {
                type = "filesystem";
                format = "ext2";
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted_nixos";
                settings.allowDiscards = true;
                passwordFile = "/tmp/secret.key";
                content = {
                  type = "zfs";
                  pool = "zroot";
                };
              };
            };
          };
        };
      };
    };
    zpool = {
      zroot = {
        type = "zpool";
        rootFsOptions = {
          mountpoint = "none";
          compression = "zstd";
          acltype = "posixacl";
          xattr = "sa";
          "com.sun:auto-snapshot" = "true";
        };
        options.ashift = "12";
        datasets = {
          "root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options = {
              mountpoint = "legacy";
              #encryption = "aes-256-gcm";
              #keyformat = "passphrase";
              #keylocation = "prompt";
              #keylocation = "file:///tmp/secret.key";
            };

          };
          "root/nix/store" = {
            type = "zfs_fs";
            mountpoint = "/nix/store";
            options.mountpoint = "legacy";
          };
        };
      };
    };
  };
}
