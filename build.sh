#!/bin/bash

set -exo pipefail

source ./util.sh


echo "Preparing to build ${FULL_IMAGE_NAME}"

mkdir $OUTDIR
git clone https://github.com/dustymabe/build-podman-machine-os-disks

echo " Building image locally"

podman build -t "${FULL_IMAGE_NAME_ARCH}" -f podman-image-daily/Containerfile ${PWD}/podman-image-daily

echo "Saving image from image store to filesystem"

podman save --format oci-archive -o "${OUTDIR}/${DISK_IMAGE_NAME}" "${FULL_IMAGE_NAME_ARCH}"

echo "Transforming OCI image into disk image"
cd $OUTDIR && sudo sh  ../build-podman-machine-os-disks/build-podman-machine-os-disks.sh "${PWD}/${DISK_IMAGE_NAME}"

echo "Compressing disk images with zstd"
# note: we are still "in" the outdir at this point
for DISK in "${DISK_FLAVORS_W_SUFFIX[@]}"; do
  zstd -T0 -14 "${DISK_IMAGE_NAME}.${CPU_ARCH}.${DISK}"
done
