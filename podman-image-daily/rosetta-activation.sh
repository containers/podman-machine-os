#!/bin/bash
set -e

# mount rosetta tag, if the virtiofs tag does not exists do not return an error and exit early
mount -t virtiofs -o context=system_u:object_r:nfs_t:s0 rosetta /mnt || exit 0

# register rosetta handler
echo ":rosetta:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00:\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/mnt/rosetta:F" > /proc/sys/fs/binfmt_misc/register

# unregister qemu handler
echo -1 > /proc/sys/fs/binfmt_misc/qemu-x86_64
