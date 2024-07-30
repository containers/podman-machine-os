#!/bin/bash
source ./util.sh


REPO="${REPO:-quay.io/podman}"
DISK_IMAGE_NAME="${DISK_IMAGE_NAME:-stage-machine-os}"
OUTDIR="outdir"
BUILD_SCRIPT="./build-podman-machine-os-disks/build-podman-machine-os-disks.sh"
OCI_NAME="${OCI_NAME:-podman-machine-daily}"
OCI_VERSION="${OCI_VERSION:-unknown}"
FULL_IMAGE_NAME="${REPO}/${OCI_NAME}:${OCI_VERSION}"

echo "Preparing to build ${FULL_IMAGE_NAME}"

mkdir $OUTDIR
git clone https://github.com/dustymabe/build-podman-machine-os-disks

echo " Building image locally"

podman build -t "${FULL_IMAGE_NAME}" -f podman-image-daily/Containerfile ${PWD}/podman-image-daily

echo "Saving image from image store to filesystem"

podman save --format oci-archive -o "${OUTDIR}/${DISK_IMAGE_NAME}" "${FULL_IMAGE_NAME}"

echo "Transforming OCI image into disk image"
cd $OUTDIR && sudo sh  ../build-podman-machine-os-disks/build-podman-machine-os-disks.sh "${PWD}/${DISK_IMAGE_NAME}"

echo "Compressing disk images with zstd"
# note: we are still "in" the outdir at this point
for DISK in "${DISK_FLAVORS_W_SUFFIX[@]}"; do
  zstd -T0 -14 "${DISK_IMAGE_NAME}.${CPU_ARCH}.${DISK}"
done
