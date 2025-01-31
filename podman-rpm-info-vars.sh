#!/usr/bin/env bash

# Set to "dev" to pull from the podman-next copr, set to "release"
# to pull the rpm from the release PR's copr build job.
export PODMAN_RPM_TYPE="release"

# PODMAN_VERSION is always used to derive the machine-os image tag (x.y) so this must be valid
# at any given time.
export PODMAN_VERSION="5.5.0-dev"
export PODMAN_PR_NUM="24369"
