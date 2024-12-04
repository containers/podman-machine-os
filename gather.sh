#!/bin/bash

set -exo pipefail

source ./util.sh

# This script assume that the build disk images/oci image exists in $OUTDIR.

cirrusBuildIdAnnoation=""
if [[ -n $CIRRUS_BUILD_ID ]]; then
  cirrusBuildIdAnnoation="--annotation cirrus.buildid=$CIRRUS_BUILD_ID"
fi

# Create our manifest
buildah manifest create $cirrusBuildIdAnnoation "${FULL_IMAGE_NAME}"

# Load and add OCI image to manifest
for arch in "${!ARCH_TO_IMAGE_ARCH[@]}"; do
  podman load -i "${OUTDIR}/${DISK_IMAGE_NAME}.${arch}.tar"
  buildah manifest add --arch ${ARCH_TO_IMAGE_ARCH[$arch]} "${FULL_IMAGE_NAME}" "$FULL_IMAGE_NAME-${ARCH_TO_IMAGE_ARCH[$arch]}"
done


# Adds the OCI artifacts to the manifest
for itype in "${DISK_FLAVORS[@]}"; do
  for arch in "${!ARCH_TO_IMAGE_ARCH[@]}"; do
    DISK_FORMAT=$(disk_format_from_flavor "${itype}")
    COMPRESSED_DISK="${OUTDIR}/${DISK_IMAGE_NAME}.${arch}.${itype}.${DISK_FORMAT}.zst"
	  buildah manifest add --artifact --artifact-type=""  --os=linux --arch=$arch --annotation "disktype=${itype}" "${FULL_IMAGE_NAME}" "$COMPRESSED_DISK"
  done
done
