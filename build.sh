#!/bin/bash

set -exo pipefail

source ./util.sh

echo "Preparing to build ${FULL_IMAGE_NAME}"

if [[ ! -d "custom-coreos-disk-images" ]]; then
    # FIXME: pin this to a commit to net get broken all of the sudden
    git clone https://github.com/coreos/custom-coreos-disk-images
    sed -i -e 's/3072/6144/g' custom-coreos-disk-images/custom-coreos-disk-images.sh
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
    --build-arg PODMAN_VERSION=${PODMAN_VERSION} \
    --build-arg PODMAN_RPM_RELEASE=${PODMAN_RPM_RELEASE} \
    --build-arg FEDORA_RELEASE=$(rpm --eval '%{?fedora}') \
    --build-arg ARCH=$(uname -m)

echo "Saving image from image store to filesystem"

mkdir -p $OUTDIR
podman save --format oci-archive -o "${OUTDIR}/${DISK_IMAGE_NAME}" "${FULL_IMAGE_NAME_ARCH}"

echo "Transforming OCI image into disk image"
pushd $OUTDIR && sh $SRCDIR/custom-coreos-disk-images/custom-coreos-disk-images.sh \
  --platforms applehv,hyperv,qemu \
  --ociarchive "${PWD}/${DISK_IMAGE_NAME}" \
  --osname fedora-coreos \
  --imgref "ostree-remote-registry:fedora:docker://quay.io/podman/machine-os:${PODMAN_VERSION%.*}"

echo "Compressing disk images with zstd"
# note: we are still "in" the outdir at this point
for DISK in "${DISK_FLAVORS_W_SUFFIX[@]}"; do
  zstd --rm -T0 -14 "${DISK_IMAGE_NAME}.${CPU_ARCH}.${DISK}"
done

popd
