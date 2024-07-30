#!/bin/bash

source ./util.sh

buildah manifest create "${FULL_IMAGE_NAME}"
# This section adds the OCI artifacts to the manifest
for itype in "${DISK_FLAVORS[@]}"; do
  for arch in "${ARCHES[@]}"; do
    DISK_FORMAT=$(disk_format_from_flavor "${itype}")
    COMPRESSED_DISK="${OUTDIR}/${DISK_IMAGE_NAME}.${arch}.${itype}.${DISK_FORMAT}.zst"
	  echo "buildah manifest add --artifact --artifact-type=""  --os=linux --arch=$arch --annotation "disktype=${itype}" ${FULL_IMAGE_NAME} ${COMPRESSED_DISK}"
	  buildah manifest add --artifact --artifact-type=""  --os=linux --arch=$arch --annotation "disktype=${itype}" "${FULL_IMAGE_NAME}" "$COMPRESSED_DISK"
  done
done

# This section adds the images to the manifest as well
for arch in "${IMAGE_ARCHES[@]}"; do
 buildah manifest add --arch $arch "${FULL_IMAGE_NAME}" "${FULL_IMAGE_NAME}-$arch"
done

