#!/bin/bash

source ./podman-rpm-info-vars.sh

CPU_ARCH=`lscpu --json | jq .lscpu.[0].data | tr -d '"'`
ARCHES=("x86_64" "aarch64")
IMAGE_ARCHES=("amd64" "arm64")

image_arch_from_cpu () {
  case "$CPU_ARCH" in
    "x86_64")
    echo "amd64"
    ;;
    "aarch64")
    echo "arm64"
    ;;
  esac
}

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
    *)
      echo "unknown flavor $1"
      exit
      ;;
  esac
}


DISK_FLAVORS=("applehv" "hyperv" "qemu")
DISK_FLAVORS_W_SUFFIX=("applehv.raw" "hyperv.vhdx" "qemu.qcow2")

REPO="${REPO:-quay.io/podman}"
# OUTDIR needs to be run in TMT test as a non-root user after initial root
# login
export OUTDIR="${TMT_TEST_DATA:-$(git rev-parse --show-toplevel)/outdir}"
BUILD_SCRIPT="./build-podman-machine-os-disks/build-podman-machine-os-disks.sh"
if [[ ${PODMAN_RPM_TYPE} != "dev" ]]; then
    export OCI_NAME="machine-os-$PODMAN_VERSION"
    export DISK_IMAGE_NAME="$OCI_NAME-$PODMAN_RPM_RELEASE"
else
    export OCI_NAME="${OCI_NAME:-podman-machine-daily}"
    export DISK_IMAGE_NAME="${DISK_IMAGE_NAME:-stage-machine-os}"
fi
OCI_VERSION="${OCI_VERSION:-unknown}"
FULL_IMAGE_NAME="${REPO}/${OCI_NAME}:${OCI_VERSION}"


FULL_IMAGE_NAME_ARCH="$FULL_IMAGE_NAME-"$(image_arch_from_cpu)
