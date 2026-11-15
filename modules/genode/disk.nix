{
  config,
  lib,
  ...
}:

let
  cfg = config.genode.disk;
  zfs = cfg.dom0.zfs;
  swap = zfs.swap;

  dom0Fs =
    if cfg.dom0.fs == "zfs" then
      {
        type = "zfs";
        pool = zfs.pool;
      }
    else
      {
        type = "filesystem";
        format = "ext4";
        mountpoint = "/";
      };

  dom0 =
    if cfg.dom0.luks.enable then
      {
        type = "luks";
        name = cfg.dom0.luks.name;
        passwordFile = if cfg.dom0.luks.passwordFile == "" then null else cfg.dom0.luks.passwordFile;
        settings.allowDiscards = cfg.dom0.luks.allowDiscards;
        content = dom0Fs;
      }
    else
      dom0Fs;

  size = lib.types.either (lib.types.enum [ "100%" ]) (lib.types.strMatching "[0-9]+[KMGTP]?");
in
{
  options.genode.disk = {
    enable = lib.mkEnableOption "the Genode + dom0 partition layout";

    device = lib.mkOption {
      type = lib.types.str;
      example = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_1TB_S5GXNX0T123456";
      description = "Disk to partition. No default: a wrong default is a wrong disk.";
    };

    diskName = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "Name of the disko disk attribute (and image).";
    };

    esp.size = lib.mkOption {
      type = size;
      default = "1G";
      description = "Size of the EFI system partition.";
    };

    genode = {
      size = lib.mkOption {
        type = size;
        default = "20G";
        description = "Size of the Genode partition.";
      };

      mountpoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "/genode/rw";
        description = "Where to mount the Genode partition (mounted with nofail).";
      };
    };

    dom0 = {
      fs = lib.mkOption {
        type = lib.types.enum [
          "ext4"
          "zfs"
        ];
        default = "zfs";
        description = "Filesystem for the dom0 root.";
      };

      luks = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Encrypt the dom0 partition with LUKS.";
        };

        name = lib.mkOption {
          type = lib.types.str;
          default = "crypted_dom0";
          description = "LUKS device name.";
        };

        passwordFile = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "File containing the LUKS passphrase. Empty means: ask interactively.";
        };

        allowDiscards = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Pass TRIM/discard through LUKS.";
        };
      };

      zfs = {
        pool = lib.mkOption {
          type = lib.types.str;
          default = "zroot";
          description = "Name of the zpool.";
        };

        ashift = lib.mkOption {
          type = lib.types.int;
          default = 12;
          description = "zpool ashift.";
        };

        rootFsOptions = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = {
            mountpoint = "none";
            compression = "zstd";
            acltype = "posixacl";
            xattr = "sa";
            "com.sun:auto-snapshot" = "true";
          };
          description = "zpool rootFsOptions, passed through to disko.";
        };

        datasets = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = {
            "root" = {
              type = "zfs_fs";
              mountpoint = "/";
              options.mountpoint = "legacy";
            };
            "root/nix/store" = {
              type = "zfs_fs";
              mountpoint = "/nix/store";
              options.mountpoint = "legacy";
            };
          };
          description = "disko zpool.datasets, passed through. attrsOf merges keys.";
        };

        swap = {
          size = lib.mkOption {
            type = lib.types.nullOr size;
            default = null;
            description = ''
              Size of a swap zvol inside the pool. null disables swap.
              The zvol is thick (reservation) and gets compression=off.
              Not configured as resume device: hibernation is untested.
            '';
          };

          name = lib.mkOption {
            type = lib.types.str;
            default = "swap";
            description = "Name of the swap zvol (dataset below the pool).";
          };
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      disko.devices.disk.${cfg.diskName} = {
        type = "disk";
        device = cfg.device;
        imageName = cfg.diskName;
        content = {
          type = "gpt";
          partitions = {
            bbp = {
              size = "1M";
              type = "EF02";
              label = "BBP";
            };

            esp = {
              size = cfg.esp.size;
              type = "EF00";
              label = "ESP";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };

            genode = {
              size = cfg.genode.size;
              label = "GENODE*";
              content = {
                type = "filesystem";
                format = "ext2";
                mountpoint = cfg.genode.mountpoint;
                mountOptions = [ "nofail" ];
              };
            };

            dom0 = {
              size = "100%";
              content = dom0;
            };
          };
        };
      };
    })

    (lib.mkIf (cfg.enable && cfg.dom0.fs == "zfs") {
      disko.devices.zpool.${zfs.pool} = {
        type = "zpool";
        rootFsOptions = zfs.rootFsOptions;
        options.ashift = toString zfs.ashift;
        datasets = zfs.datasets // lib.optionalAttrs (swap.size != null) {
          ${swap.name} = {
            type = "zfs_volume";
            size = swap.size;
            options.compression = "off";
            content = {
              type = "swap";
            };
          };
        };
      };
    })

    {
      assertions = [
        {
          assertion = !(cfg.dom0.fs != "zfs" && swap.size != null);
          message = "genode.disk.dom0.zfs.swap requires genode.disk.dom0.fs = \"zfs\"";
        }
      ];
    }
  ];
}
