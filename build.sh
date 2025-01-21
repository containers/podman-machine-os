#!/bin/bash

set -exo pipefail

source ./util.sh

echo "Preparing to build ${FULL_IMAGE_NAME}"

# Freeze on specific commit to increase stability.
# Renovate is configured to update to a new commit so do not update the format
# without updating the renovate config, see .github/renovate.json5.
gitreporef="06c3faf27826e17d6ea051ad023ba38879593e1b"
gitrepotld="https://raw.githubusercontent.com/coreos/custom-coreos-disk-images/${gitreporef}/"
curl -LO --fail "${gitrepotld}/custom-coreos-disk-images.sh"

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
pushd $OUTDIR && sh $SRCDIR/custom-coreos-disk-images.sh \
  --platforms applehv,hyperv,qemu \
  --ociarchive "${PWD}/${DISK_IMAGE_NAME}" \
  --osname fedora-coreos \
  --imgref "ostree-remote-registry:fedora:$FULL_IMAGE_NAME" \
  --metal-image-size 6144 \
  --extra-kargs='ostree.prepare-root.composefs=0'


declare -A COREOS_PLATFORM_SUFFIX=(
    ['applehv']='raw'
    ['hyperv']='vhdx'
    ['qemu']='qcow2'
)

echo "Compressing disk images with zstd"
# note: we are still "in" the outdir at this point
for hypervisor in "${!COREOS_PLATFORM_SUFFIX[@]}"; do
  # Rename the file to our preferred format
  extension="${COREOS_PLATFORM_SUFFIX[$hypervisor]}"
  filename="${DISK_IMAGE_NAME}-${hypervisor}.${CPU_ARCH}.${extension}"
  newfilename="${DISK_IMAGE_NAME}.${CPU_ARCH}.${hypervisor}.${extension}"
  mv "$filename" "$newfilename"

  # Compress the file
  zstd --rm -T0 -14 "$newfilename"
done

popd
