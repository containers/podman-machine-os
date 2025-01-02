#!/usr/bin/env bash

# Set to "dev" to pull from the podman-next copr, set to "release"
# to pull the rpm from the release PR's copr build job.
export PODMAN_RPM_TYPE="dev"

# PODMAN_VERSION is always used to derive the machine-os image tag (x.y) so this must be valid
# at any given time.
# Both PODMAN_VERSION and PODMAN_PR_NUM will have to be updated manually on release
# PRs.
export PODMAN_VERSION="5.5.0-dev"
export PODMAN_PR_NUM="24369"
