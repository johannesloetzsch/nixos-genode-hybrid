# VMDK files for block devices

```sh
VBoxManage internalcommands createrawvmdk -filename block.vmdk -rawdisk /dev/sda1 -partitions 1,2,4 -relative
```
