#!/bin/bash

set -exo pipefail

source ./util.sh

echo "Preparing to build ${FULL_IMAGE_NAME}"

if [[ ! -d "build-podman-machine-os-disks" ]]; then
    git clone https://github.com/dustymabe/build-podman-machine-os-disks
    sed -i -e 's|fedora:quay.io/containers.*"|fedora:quay.io/podman/machine-os:${PODMAN_VERSION%.*}"|' build-podman-machine-os-disks/build-podman-machine-os-disks.sh
fi

echo " Building image locally"

# Validate podman RPM type var, see the Containerfile for the pull logic.
case "${PODMAN_RPM_TYPE}" in
  "dev") echo "Will install podman from the podman-next copr, the podman version is ignored" ;;
  "release") ;;
  *) echo 'PODMAN_RPM_TYPE must be set to "dev" or "release"' 1>&2; exit 1
esac

# See podman-rpm-info-vars.sh for all build-arg values. If PODMAN_RPM_TYPE is
# "dev", the rpm version, release and fedora release values are of no concern
# to the build process.
podman build -t "${FULL_IMAGE_NAME_ARCH}" -f podman-image/Containerfile ${PWD}/podman-image \
    --build-arg PODMAN_RPM_TYPE=${PODMAN_RPM_TYPE} \

echo "Saving image from image store to filesystem"

mkdir -p $OUTDIR
podman save --format oci-archive -o "${OUTDIR}/${DISK_IMAGE_NAME}" "${FULL_IMAGE_NAME_ARCH}"

echo "Transforming OCI image into disk image"
pushd $OUTDIR && sh $SRCDIR/build-podman-machine-os-disks/build-podman-machine-os-disks.sh "${PWD}/${DISK_IMAGE_NAME}"

echo "Compressing disk images with zstd"
# note: we are still "in" the outdir at this point
for DISK in "${DISK_FLAVORS_W_SUFFIX[@]}"; do
  zstd --rm -T0 -14 "${DISK_IMAGE_NAME}.${CPU_ARCH}.${DISK}"
done

popd
