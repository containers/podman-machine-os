# Machine Image Verification Tests

## What this is for
When a new podman machine disk image is created, it should be verified to work
and that no regressions have been introduced.  When something is changed in
the Containerfile that builds the image, a regression test should be added
here to make sure any changes are caught and documented.

## How do I use this
### Prerequisites
To run these tests, a few things need to be in order prior.
1. Podman binary appropriate for the platform built and in the $PATH.
2. Gingko (v2) must be in your $PATH
2. All supporting binaries, gvproxy, vfkit, etc also installed
3. Downloaded the appropriate disk image for the platform to a known path

### Which Podman binary should be tested with
Podman binary names will differ based on operating system.  For Linux, use
the `podman-remote` binary.  For all other platforms, use the `podman` binary.

### How to run the image verification tests

The tests need to be run from the `podman-machine-os/verify` directory. The syntax
for the test script is as follows:

`$ sh run_test.sh /path/to/disk/image`

You can also set the path to the disk image with an environment variable such as:

`$ PODMAN_MACHINE_IMAGE=/path/to/disk/image sh run_test.sh`

On MacOS, **you will need to set the TMPDIR environment variable** to avoid a
limitation in MacOS where socket lengths cannot exceed 120-some characters.
For example:

`$ TMPDIR=/Users/brentbaude/ sh run_test.sh /path/to/disk/image`

### Operating Systems with multiple machine providers

Both Windows and MacOS support multiple machine providers. Windows supports
`WSL` and `HyperV`, where WSL is the default provider.  On MacOS, `applehv` and `libkrun`
are both supported and `applehv` is the default. You can also the provider used by
the tests with an environment variable, such as the following on MacOS:

`$ TMPDIR=/Users/brentbaude CONTAINERS_MACHINE_PROVIDER=libkrun sh run_test.sh /path/to/disk/image`