{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLB256HAHQ-000L7_S41GNX4M436369";
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
            NIXOS = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
