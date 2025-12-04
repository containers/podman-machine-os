#!/bin/bash

source ./podman-rpm-info-vars.sh

CPU_ARCH=$(uname -m)
declare -A ARCH_TO_IMAGE_ARCH=(
    ["x86_64"]="amd64"
    ["aarch64"]="arm64"
)


disk_format_from_flavor () {
  if [[ -z $1 ]]; then
    echo "no disk flavor passed"
    exit
  fi

  case $1 in
    "applehv")
      echo "raw"
      ;;
    "hyperv")
      echo "vhdx"
      ;;
    "qemu")
      echo "qcow2"
      ;;
    "wsl")
      echo "tar"
      ;;
    *)
      echo "unknown flavor $1"
      exit 1
      ;;
  esac
}


DISK_FLAVORS=("applehv" "hyperv" "qemu" "wsl")

# OUTDIR needs to be run in TMT test as a non-root user after initial root
# login
export SRCDIR="${TMT_TREE:-${CIRRUS_WORKING_DIR:-..}}"
export OUTDIR="${OUTDIR:-${TMT_TEST_DATA:-$(git rev-parse --show-toplevel)/outdir}}"
export DISK_IMAGE_NAME="podman-machine"

REPO="${REPO:-quay.io/podman}"
OCI_NAME="machine-os"
# Image version is only x.y so we trim of the .z part here
OCI_VERSION="${PODMAN_VERSION%.*}"
FULL_IMAGE_NAME="${REPO}/${OCI_NAME}:${OCI_VERSION}"

export FULL_IMAGE_NAME_ARCH="$FULL_IMAGE_NAME-${ARCH_TO_IMAGE_ARCH[$CPU_ARCH]}"

# For released images we want the stable stream but for early testing in CI let's use the next stream.
FCOS_STREAM="${FCOS_STREAM:-stable}"
if [[ -n "$CIRRUS_CI" ]]; then
  if [[ -z "$CIRRUS_PR" ]]; then
    DEST_BRANCH="$CIRRUS_BRANCH"
  else
    DEST_BRANCH="$CIRRUS_BASE_BRANCH"
  fi
  if [[ "$DEST_BRANCH" == "main" ]]; then
    FCOS_STREAM="next"
  fi
fi

FCOS_BASE_IMAGE="quay.io/fedora/fedora-coreos:$FCOS_STREAM"
export FCOS_BASE_IMAGE


# Remove this when we no longer need to patch OSBuild
patch_osbuild() {
    # Add a few patches that either haven't made it into a release or
    # that will be obsoleted with other work that will be done soon.
    #
    # To make it easier to apply patches we'll move around the osbuild
    # code on the system first:
    rmdir /usr/lib/osbuild/osbuild
    python_lib_dir=$(ls -d /usr/lib/python*)
    mv "${python_lib_dir}/site-packages/osbuild" /usr/lib/osbuild/
    mkdir -p /usr/lib/osbuild/tools
    mv /usr/bin/osbuild-mpp /usr/lib/osbuild/tools/
    # Now all the software is under the /usr/lib/osbuild dir and we can patch
    # shellcheck disable=SC2002
    cat \
        ./patches/0001-stages-ostree.aleph-don-t-add-docker-to-the-imgref-f.patch \
        ./patches/0002-stages-ostree.deploy.container-rework-examples-into-.patch \
        ./patches/0003-stages-ostree.-aleph-deploy.container-suport-more-im.patch \
        ./patches/0004-stages-ostree.aleph-add-more-logic-for-querying-imag.patch \
            | patch -d /usr/lib/osbuild -p1
    # And then move the files back after patching
    mv /usr/lib/osbuild/tools/osbuild-mpp /usr/bin/osbuild-mpp
    mv /usr/lib/osbuild/osbuild "${python_lib_dir}/site-packages/osbuild"
    mkdir -p /usr/lib/osbuild/osbuild
}
