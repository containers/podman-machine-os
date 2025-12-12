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
for name in $(get_oci_artifact_names); do
  output=$(podman load -i "${OUTDIR}/$name")
  arch="${ARCH_TO_IMAGE_ARCH[$(get_arch_from_name $name)]}"
  # Trim "Loaded image: " prefix
  id="${output#Loaded image: }"
  image_name="$FULL_IMAGE_NAME-$arch"
  podman tag "$id" "$image_name"
  buildah manifest add --arch $arch "${FULL_IMAGE_NAME}" "$image_name"
done


# Adds the OCI artifacts to the manifest
for name in $(get_disk_artifact_names); do
    disk_type="$(get_disk_type_from_name $name)"
    arch="$(get_arch_from_name $name)"
    buildah manifest add --artifact --artifact-type=""  --os=linux --arch=$arch --annotation "disktype=${disk_type}" "${FULL_IMAGE_NAME}" "${OUTDIR}/$name"
done
