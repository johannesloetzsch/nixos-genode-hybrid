{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/ata-SAMSUNG_MZ7TY256HDHP-00000_S2YXNB0J406643";
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
                mountOptions = [ "umask=0077" ];
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
