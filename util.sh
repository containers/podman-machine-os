#!/bin/bash

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
DISK_IMAGE_NAME="${DISK_IMAGE_NAME:-stage-machine-os}"
OUTDIR="outdir"
BUILD_SCRIPT="./build-podman-machine-os-disks/build-podman-machine-os-disks.sh"
OCI_NAME="${OCI_NAME:-podman-machine-daily}"
OCI_VERSION="${OCI_VERSION:-unknown}"
FULL_IMAGE_NAME="${REPO}/${OCI_NAME}:${OCI_VERSION}"


FULL_IMAGE_NAME_ARCH="$FULL_IMAGE_NAME-"$(image_arch_from_cpu)
