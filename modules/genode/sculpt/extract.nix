## Extracts the boot tree of a Sculpt OS disk image.
##
## The image is a complete disk: partition 3 is the GENODE partition, an ext2
## filesystem that holds exactly one system image below /boot.
## The assumptions about the partition table and the filesystem label are
## asserted here, so a changed upstream layout fails the build instead of
## producing a silently wrong tree.
{ pkgs }:
{ name, image }:
pkgs.runCommand "sculpt-${name}-boot" {
  nativeBuildInputs = [
    pkgs.util-linux
    pkgs.e2fsprogs
    pkgs.jq
  ];
} ''
  img=$(readlink -f ${image}/sculpt.img)

  sfdisk -J "$img" > gpt.json
  test "$(jq '.partitiontable.partitions | length' gpt.json)" = 3

  dd if="$img" of=p3.img bs=512 status=none \
    skip=$(jq -r '.partitiontable.partitions[2].start' gpt.json) \
    count=$(jq -r '.partitiontable.partitions[2].size' gpt.json)

  test "$(dumpe2fs -h p3.img 2>/dev/null | sed -n 's/^Filesystem volume name: *//p')" = GENODE

  mkdir $out
  debugfs -R "rdump /boot $out" p3.img >/dev/null
  test -f $out/boot/grub/grub.cfg
''
