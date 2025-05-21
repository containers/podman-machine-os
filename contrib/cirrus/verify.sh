#!/usr/bin/env bash

set -xeo pipefail

source /etc/ci_environment

# switch to rootless user and rexec
if [ $(id -u) -eq 0 ]; then
   chown -R $ROOTLESS_USER .
   # pass through $OUTDIR
   ssh $ROOTLESS_USER@localhost "cd $CIRRUS_WORKING_DIR; MACHINE_IMAGE_BASE_URL="${MACHINE_IMAGE_BASE_URL}" MACHINE_IMAGE="${MACHINE_IMAGE}" $0"
   exit
fi

curl --retry 5 --retry-delay 8 --fail --location -O --url "${MACHINE_IMAGE_BASE_URL}${MACHINE_IMAGE}"

source ./util.sh
mkdir -p bin
cd verify
go build -o ../bin/ginkgo ./vendor/github.com/onsi/ginkgo/v2/ginkgo
export MACHINE_IMAGE_PATH="../${MACHINE_IMAGE}"
../bin/ginkgo -v
