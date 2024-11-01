#!/bin/bash

set -exo pipefail

source ./util.sh

echo "Preparing to build ${FULL_IMAGE_NAME}"

# THIS WILL CHANGE AFTER
# https://github.com/coreos/custom-coreos-disk-images/pull/6/files is merged
rm -f custom-coreos-disk-images
git clone https://github.com/dustymabe/custom-coreos-disk-images
pushd custom-coreos-disk-images
git checkout dusty-updates
git am < ../0001-use-var-tmp-for-tmpdir.patch
popd

echo " Building image locally"

# See podman-rpm-info-vars.sh for all build-arg values. If PODMAN_RPM_TYPE is
# "dev", the rpm version, release and fedora release values are of no concern
# to the build process.
podman build -t "${FULL_IMAGE_NAME_ARCH}" -f podman-image/Containerfile ${PWD}/podman-image \
    --build-arg PODMAN_RPM_TYPE=${PODMAN_RPM_TYPE} \
    --build-arg PODMAN_VERSION=${PODMAN_VERSION} \
    --build-arg PODMAN_RPM_RELEASE=${PODMAN_RPM_RELEASE} \
    --build-arg FEDORA_RELEASE=$(rpm --eval '%{?fedora}') \
    --build-arg ARCH=$(uname -m)

echo "Saving image from image store to filesystem"

mkdir -p $OUTDIR
podman save --format oci-archive -o "${OUTDIR}/${DISK_IMAGE_NAME}" "${FULL_IMAGE_NAME_ARCH}"

echo "Transforming OCI image into disk image"
SRCDIR="${TMT_TREE:-..}"
pushd $OUTDIR && sudo sh $SRCDIR/custom-coreos-disk-images/custom-coreos-disk-images.sh --ociarchive "${PWD}/${DISK_IMAGE_NAME}" --platforms applehv,hyperv,qemu
echo "Compressing disk images with zstd"
# note: we are still "in" the outdir at this point
for DISK in "${DISK_FLAVORS_W_SUFFIX[@]}"; do
  zstd --rm -T0 -14 "${DISK_IMAGE_NAME}.${CPU_ARCH}.${DISK}"
done

popd
