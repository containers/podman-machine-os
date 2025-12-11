#!/usr/bin/env bash

CIRRUS_BUILD_ID=$1

if [[ -z "$CIRRUS_BUILD_ID" ]]; then
    echo "Requires cirrus build as first argument" 1>&2
    exit 1
fi

# Source util.sh to get platform mappings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../util.sh"

# Helper function to check if an arch supports a platform artifact
arch_supports_platform() {
    local arch=$1
    local platform_ext=$2
    local supported_exts=$(get_artifact_extensions_for_arch "$arch")
    [[ " $supported_exts " =~ " $platform_ext " ]]
}

echo "Image Downloads for cirrus build [${CIRRUS_BUILD_ID}](https://cirrus-ci.com/build/${CIRRUS_BUILD_ID}):"
echo
echo "| x86_64 | aarch64 |"
echo "| --- | --- |"

for end in applehv.raw.zst hyperv.vhdx.zst qemu.qcow2.zst wsl.tar.zst tar; do
    for arch in x86_64 aarch64; do
        if arch_supports_platform "$arch" "$end"; then
            name="podman-machine.$arch.$end"
            echo -n "| [$name](https://api.cirrus-ci.com/v1/artifact/build/${CIRRUS_BUILD_ID}/image_build/image/$name) "
        else
            echo -n "| N/A "
        fi
    done
    echo "|"
done

echo
echo "[Everything zip](https://api.cirrus-ci.com/v1/artifact/build/${CIRRUS_BUILD_ID}/image.zip)"
