#!/bin/bash

# qemu-img create -f qcow2 mac_hdd.img 64G
# echo 1 > /sys/module/kvm/parameters/ignore_msrs
#
# Type the following after boot,
# -v "KernelBooter_kexts"="Yes" "CsrActiveConfig"="103"
#
# printf 'DE:AD:BE:EF:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256))
#
# no_floppy = 1 is required for OS X guests!
#
# Commit 473a49460db0a90bfda046b8f3662b49f94098eb (qemu) makes "no_floppy = 0"
# for pc-q35-2.3 hardware, and OS X doesn't like this (it hangs at "Waiting for
# DSMOS" message). Hence, we switch to pc-q35-2.4 hardware.
#
# Network device "-device e1000-82545em" can be replaced with "-device vmxnet3"
# for possibly better performance.
BACKING_DIR=/backing
SNAPSHOT_DIR=/snapshot
mkdir -p $BACKING_DIR $SNAPSHOT_DIR
[ ! -f $SNAPSHOT_DIR/mac_hdd.img ] && qemu-img create -f qcow2 -b $BACKING_DIR/mac_hdd-backing.img $SNAPSHOT_DIR/mac_hdd.img

if [ -c /dev/kvm ]; then
  KVM_ARGS='-enable-kvm'
fi

exec qemu-system-x86_64 $KVM_ARGS -m 3072 -cpu Penryn,kvm=off,vendor=GenuineIntel \
  -machine pc-q35-2.4 \
  -smp 4,cores=2 \
  -usb -device usb-kbd -device usb-mouse \
  -device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" \
  -kernel /usr/lib/qemu/enoch_rev2902_boot \
  -smbios type=2 \
  -device ich9-intel-hda -device hda-duplex \
  -device ide-drive,bus=ide.2,drive=MacHDD \
  -drive id=MacHDD,if=none,file=$SNAPSHOT_DIR/mac_hdd.img \
  -netdev user,id=usr0 -device e1000-82545em,netdev=usr0,id=vnet0 \
  -monitor stdio \
  -display none -redir tcp:2222::22 -vnc 0.0.0.0:0
  # -netdev tap,id=net0,ifname=tap0,script=no,downscript=no -device vmxnet3,netdev=net0,id=net0,mac=52:54:00:ab:65:3e \
