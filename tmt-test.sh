#!/usr/bin/env bash

set -exo pipefail

setenforce 0

. build.sh

chown -R fedora:fedora ./*

pushd verify
runuser fedora -c 'go install github.com/onsi/ginkgo/v2/ginkgo'
runuser fedora -c 'TMPDIR=/var/tmp MACHINE_IMAGE_PATH="$OUTDIR/$DISK_IMAGE_NAME.$ARCH.qemu.qcow2.zst" PATH=$PATH:~/go/bin sh run_test.sh'
popd
