#!/bin/bash

REPO="quay.io/podman"
IMAGE_NAME="stage-machine-os:latest"
OUTDIR="daily_out"
BUILD_SCRIPT="./build-podman-machine-os-disks/build-podman-machine-os-disks.sh"
OCI_NAME="podman-machine-daily"

mkdir $OUTDIR
git clone https://github.com/dustymabe/build-podman-machine-os-disks

podman build -t "${REPO}/${IMAGE_NAME}" -f podman-image-daily/Containerfile ${PWD}/podman-image-daily

podman save --format oci-archive -o ${OUTDIR}/${OCI_NAME} "${REPO}/${IMAGE_NAME}"

cd $OUTDIR && sudo sh  ../build-podman-machine-os-disks/build-podman-machine-os-disks.sh ${PWD}/${OCI_NAME}
