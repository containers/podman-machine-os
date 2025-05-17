# podman-machine-os

This repo is for building the disk images for podman machine.

## Building the image

### Requirements:
- Only runs on Linux as root
- `curl`
- `podman` (rootful)
- `rpm-ostree`
- `zstd`
- `SELinux` in permissive mode?
- `osbuild`, `osbuild-tools`, `osbuild-ostree`, `jq`, `xfsprogs`, `e2fsprogs` (custom-coreos-disk-image.sh reqs)
- `koji` (only if building podman from a PR)


Env variables that affect the build:
`OUTDIR`: folder where the images are generated. The default is `./outdir`.
`REPO`: container registry repo where the image are pushed? The default is `quay.io/podman`.

...in `podman-rmp-info-vars.sh`
`PODMAN_VERION`: used for the image tag (only the x.y, the patch version is ignored)
`PODMAN_PR_NUM`: used to add a podman version from a PR. The default is podman-next copr

## Running the tests

### Requirements

golang
ginkgo (`cd ./verify && go install github.com/onsi/ginkgo/v2/ginkgo`)
