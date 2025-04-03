#!/usr/bin/env bash

# Set to "dev" to pull from the podman-next copr, set to "release"
# to pull the ext rom from the fedora build system based of the versions below.
export PODMAN_RPM_TYPE="release"

# PODMAN_VERSION is used for fetching the right rpm when PODMAN_RPM_TYPE is set to release.
# However it is always used to derive the machine-os image tag (x.y) so this must be valid
# at any given time.
export PODMAN_VERSION="5.4.2"
export PODMAN_RPM_RELEASE="1"
