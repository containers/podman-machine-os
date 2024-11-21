#!/usr/bin/env bash

# Set to "dev" to pull from the podman-next copr, set to "release"
# to pull the ext rom from the fedora build system based of the versions below.
export PODMAN_RPM_TYPE="release"

# If PODMAN_RPM_TYPE is "dev", the vars below don't end up getting used in the
# build
export PODMAN_VERSION="5.3.1"
export PODMAN_RPM_RELEASE="1"
