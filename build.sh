#!/bin/bash

set -exo pipefail

source ./util.sh
source ./podman-rpm-info-vars.sh

echo "Preparing to build ${FULL_IMAGE_NAME}"

if [[ ! -d "build-podman-machine-os-disks" ]]; then
    git clone https://github.com/dustymabe/build-podman-machine-os-disks
fi

echo " Building image locally"

podman build -t "${FULL_IMAGE_NAME_ARCH}" -f podman-image-daily/Containerfile ${PWD}/podman-image-daily --build-arg PODMAN_VERSION=${PODMAN_VERSION} --build-arg PODMAN_RPM_RELEASE=${PODMAN_RPM_RELEASE} --build-arg FEDORA_RELEASE=${FEDORA_RELEASE} --build-arg ARCH=${ARCH}

echo "Saving image from image store to filesystem"

mkdir -p $OUTDIR
podman save --format oci-archive -o "${OUTDIR}/${DISK_IMAGE_NAME}" "${FULL_IMAGE_NAME_ARCH}"

echo "Transforming OCI image into disk image"
SRCDIR="${TMT_TREE:-..}"
cd $OUTDIR && sudo sh $SRCDIR/build-podman-machine-os-disks/build-podman-machine-os-disks.sh "${PWD}/${DISK_IMAGE_NAME}"

echo "Compressing disk images with zstd"
# note: we are still "in" the outdir at this point
for DISK in "${DISK_FLAVORS_W_SUFFIX[@]}"; do
  zstd -T0 -14 "${DISK_IMAGE_NAME}.${CPU_ARCH}.${DISK}"
done
