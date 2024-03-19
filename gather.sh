#!/bin/bash

arches=("x86_64" "aarch64")
imagetypes=("applehv" "hyperv" "qemu")

if [ "$#" -ne 2 ]; then
    echo "gather image-manifest-name base-coreos-name"
    exit 1
fi

buildah manifest create $1

for itype in "${imagetypes[@]}"
do
  for arch in "${arches[@]}"
  do
	#file=$(/bin/ls $2-$itype.$arch.*)
	file=$(/bin/ls $2.$arch.$itype.*.zst)
	if [[ -z "$file" ]]; then
		echo "doh"
		exit 1
	fi
	echo $file
	# removals from first incantation --artifact-config-type="application/vnd.oci.image.config.v1+json" --artifact-layer-type=application/vnd.oci.image.layer.v1.tar
	echo "buildah manifest add --artifact --artifact-type=""  --os=linux --arch=$arch --annotation "disktype=${itype}" $1 $file"
	buildah manifest add --artifact --artifact-type=""  --os=linux --arch=$arch --annotation "disktype=${itype}" $1 $file
  done
done
