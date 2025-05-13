#!/usr/bin/env bash
set -e

SCULPT_RELEASE="25-04"
SCULPT_URL="https://genode.org/files/sculpt/sculpt-${SCULPT_RELEASE}.img"

TMP="/tmp"

[ -f ${TMP}/sculpt.img ] || wget ${SCULPT_URL} -O ${TMP}/sculpt.img
7z x ${TMP}/sculpt.img -o${TMP}/sculpt
7z x ${TMP}/sculpt/GENODE.img -o${TMP}/genode

[ -d ${TMP}/mnt/genode ] || mkdir -p ${TMP}/mnt/genode
mount /dev/disk/by-partlabel/GENODE* ${TMP}/mnt/genode
cp -r ${TMP}/genode/boot ${TMP}/mnt/genode
cp ${TMP}/genode/boot/boot.png /boot/background_genode.png  ## optional
umount ${TMP}/mnt/genode
