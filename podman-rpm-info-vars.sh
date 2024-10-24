#!/usr/bin/env bash

# Set PODMAN_RPM_TYPE to anything other than "dev" to build release rpms.
export PODMAN_RPM_TYPE="dev"

# If PODMAN_RPM_TYPE is "dev", the vars below don't end up getting used in the
# build
export PODMAN_VERSION="5.2.4"
export PODMAN_RPM_RELEASE="1"
export FEDORA_RELEASE="40"
export ARCH=$(uname -m)
