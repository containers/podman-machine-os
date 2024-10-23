#!/usr/bin/env bash

set -xeo pipefail

source /etc/ci_environment

# switch to rootless user and rexec
if [ $(id -u) -eq 0 ]; then
   chown -R $ROOTLESS_USER .
   # pass through $OUTDIR
   ssh $ROOTLESS_USER@localhost "cd $CIRRUS_WORKING_DIR; OUTDIR=$OUTDIR $0"
   exit
fi

source ./util.sh
mkdir -p bin
cd verify
go build -o ../bin/ginkgo ./vendor/github.com/onsi/ginkgo/v2/ginkgo
export MACHINE_IMAGE_PATH="../$OUTDIR/$DISK_IMAGE_NAME.$ARCH.qemu.qcow2.zst"
../bin/ginkgo -v
