# podman-machine-os

This repo is for building the disk images for podman machine.

## Building the image

Note this repo use git submodules. You must either clone the repo with `--recurse-submodules` or
run `git submodule update --init`

`./build.sh`

### Requirements:

- Only runs on Linux as root
- `curl`
- `podman` (rootful)
- `rpm-ostree`
- `zstd`
- `SELinux` in permissive mode?
- `osbuild`, `osbuild-tools`, `osbuild-ostree`, `jq`, `xfsprogs`, `e2fsprogs`
  (custom-coreos-disk-image.sh reqs)
- `koji` (only if building podman from a PR)

Environment variables that affect the build:

- `OUTDIR`: folder where the images are generated. The default is `./outdir`.
- `REPO`: container registry repository used when tagging the image. The default
  is `quay.io/podman`.

Some environment variables are set in `podman-rpm-info-vars.sh`:

- `PODMAN_VERSION`: used for the image tag (only the x.y, the patch version is
  ignored)
- `PODMAN_PR_NUM`: used to add a podman version from a PR. The default is empty
  (and rpms will be fetched from the `rhcontainerbot/podman-next` copr)

## Running the tests

See ./verify/README.md

### Requirements

- golang
- ginkgo (`cd ./verify && go install github.com/onsi/ginkgo/v2/ginkgo`)
