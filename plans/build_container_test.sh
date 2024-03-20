#!/usr/bin/env bash

set -exo pipefail

podman build -t quay.io/podman/machine-os:latest -f podman-image-daily/Containerfile ${PWD}/podman-image-daily
