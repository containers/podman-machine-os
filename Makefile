REPO ?= "quay.io/podman"
IMAGE_NAME ?= "stage-machine-os:latest"
OUTDIR ?= "daily_out"
BUILD_SCRIPT ?= ./build-podman-machine-os-disks/build-podman-machine-os-disks.sh
OCI_NAME ?= "podman-machine-daily"
ARCHES ?= "x86_64 aarch64"

all: build-os-disks

permissive-mode:
	sudo setenforce 0

build-container:
	podman build -t "${REPO}/${IMAGE_NAME}" -f podman-image-daily/Containerfile $(shell pwd)/podman-image-daily

build-os-disks: build-container permissive-mode
	mkdir -p $(shell pwd)/${OUTDIR}
	podman save --format oci-archive -o ${OUTDIR}/${OCI_NAME} "${REPO}/${IMAGE_NAME}"
	git clone https://github.com/dustymabe/build-podman-machine-os-disks
	sudo sh ${BUILD_SCRIPT} $(shell pwd)/${OUTDIR}/${OCI_NAME}

clean:
	rm -rf $(shell pwd)/build-podman-machine-os-disks
	podman rmi -f "${REPO}/${IMAGE_NAME}"
	@echo "Setting selinux back to enforcing.."
	sudo setenforce 1
