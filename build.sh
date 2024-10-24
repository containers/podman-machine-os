#!/bin/bash

set -exo pipefail

source ./util.sh

echo "Preparing to build ${FULL_IMAGE_NAME}"

if [[ ! -d "build-podman-machine-os-disks" ]]; then
    git clone https://github.com/dustymabe/build-podman-machine-os-disks
fi

echo " Building image locally"

# See podman-rpm-info-vars.sh for all build-arg values. If PODMAN_RPM_TYPE is
# "dev", the rpm version, release and fedora release values are of no concern
# to the build process.
podman build -t "${FULL_IMAGE_NAME_ARCH}" -f podman-image/Containerfile ${PWD}/podman-image \
    --build-arg PODMAN_RPM_TYPE=${PODMAN_RPM_TYPE} \
    --build-arg PODMAN_VERSION=${PODMAN_VERSION} \
    --build-arg PODMAN_RPM_RELEASE=${PODMAN_RPM_RELEASE} \
    --build-arg FEDORA_RELEASE=${FEDORA_RELEASE} \
    --build-arg ARCH=${ARCH}

echo "Saving image from image store to filesystem"

mkdir -p $OUTDIR
podman save --format oci-archive -o "${OUTDIR}/${DISK_IMAGE_NAME}" "${FULL_IMAGE_NAME_ARCH}"

echo "Transforming OCI image into disk image"
SRCDIR="${TMT_TREE:-..}"
pushd $OUTDIR && sudo sh $SRCDIR/build-podman-machine-os-disks/build-podman-machine-os-disks.sh "${PWD}/${DISK_IMAGE_NAME}"

echo "Compressing disk images with zstd"
# note: we are still "in" the outdir at this point
for DISK in "${DISK_FLAVORS_W_SUFFIX[@]}"; do
  zstd -T0 -14 "${DISK_IMAGE_NAME}.${CPU_ARCH}.${DISK}"
done

popd
