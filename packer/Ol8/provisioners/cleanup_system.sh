#!/usr/bin/env bash

test "$UID" -eq 0 || exec sudo -E bash "$0"

DISK_USAGE_BEFORE_CLEANUP=$(df -h)

echo "==> Remove HWADDR and UUID from ifcfg scripts"
for ndev in /etc/sysconfig/network-scripts/ifcfg-*; do
    if test "$(basename $ndev)" != "ifcfg-lo"; then
        sed -i "/^HWADDR/d" "$ndev"
        sed -i "/^UUID/d" "$ndev"
    fi
done

echo "==> Removing random seed"
# Reference: https://www.freedesktop.org/software/systemd/man/systemd-random-seed.service.html
rm -f /var/lib/systemd/random-seed

echo "==> Remove orphaned packages"
dnf autoremove -y

echo "==> Remove previous kernels preserved for rollbacks"
dnf remove -y $(dnf repoquery --installonly --latest-limit=-1 -q)

echo "==> Remove linux-firmware package to free ~477MB of space"
dnf remove -y linux-firmware

echo "==> Truncate the unique machine-id"
truncate -s 0 /etc/machine-id

echo "==> Rebuild RPM DB"
rpmdb --rebuilddb
rm -f /var/lib/rpm/__db*

echo "==> Remove temporary files"
rm -rf /var/tmp/*
rm -rf /tmp/*

echo "==> Removes kickstart logs"
rm -f /root/anaconda-ks.cfg
rm -f /root/original-ks.cfg

echo "==> Remove .bash_history"
rm -f /home/.bash_history
find /home -type f -name .bash_history -exec rm -f {} \;

echo "==> Zeroing out empty area to save space in the final image"
# Zero out the free space to save space in the final image. Contiguous zeroed
# space compresses down to nothing.
dd if=/dev/zero of=/EMPTY bs=1M || echo "dd exit code $? is suppressed"
rm -f /EMPTY

# Block until the empty file has been removed, otherwise, Packer will try to
# kill the box while the disk is still full and that is bad.
sync

echo "==> Disk usage before cleanup"
echo "$DISK_USAGE_BEFORE_CLEANUP"

echo "==> Disk usage after cleanup"
df -h
