#!/usr/bin/env bash

CIRRUS_BUILD_ID=$1

if [[ -z "$CIRRUS_BUILD_ID" ]]; then
    echo "Requires cirrus build as first argument" 1>&2
    exit 1
fi

# Source util.sh to get platform mappings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../util.sh"

echo "Image Downloads for cirrus build [${CIRRUS_BUILD_ID}](https://cirrus-ci.com/build/${CIRRUS_BUILD_ID}):"
echo

echo -n "| Provider "

line="| --- "
for arch in "${!ARCH_TO_PLATFORMS[@]}"; do
  echo -n "| $arch "
  line+="| --- "
done
echo "|"
line+="|"
echo "$line"

declare -A map
declare -A providers

# sort names by hypervisor
for name in $(get_all_artifact_names); do
    disk_type="$(get_disk_type_from_name $name)"
    arch="$(get_arch_from_name $name)"
    map["$disk_type-$arch"]="$name"
    providers["$disk_type"]=
done

for provider in ${!providers[*]} ; do
    echo -n "| $provider "
    for arch in "${!ARCH_TO_PLATFORMS[@]}"; do
        name="${map["$provider-$arch"]}"
        if [ -n "$name" ]; then
            echo -n "| [$name](https://api.cirrus-ci.com/v1/artifact/build/${CIRRUS_BUILD_ID}/image_build/image/$name) "
        else
            echo -n "| N/A "
        fi
    done

     echo "|"
done

echo
echo "[Everything zip](https://api.cirrus-ci.com/v1/artifact/build/${CIRRUS_BUILD_ID}/image.zip)"
