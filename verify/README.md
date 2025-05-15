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

Set the `PODMAN_BINARY` environment variable to specify the path of the binary
to use.

### How to run the image verification tests

The tests need to be run from the `podman-machine-os/verify` directory. The syntax
for the test script is as follows:

`$ sh run_test.sh /path/to/disk/image`

You can also set the path to the disk image with an environment variable such as:

`$ MACHINE_IMAGE_PATH=/path/to/disk/image sh run_test.sh`

#### MacOS
On MacOS, **you will need to set the TMPDIR environment variable** to avoid a
limitation in MacOS where socket lengths cannot exceed 120-some characters.
For example:

`$ TMPDIR=/Users/brentbaude/ sh run_test.sh /path/to/disk/image`

For MacOs, we support both `applehv` and `libkrun` machine providers.  The `applehv` provider is the default.
To switch providers in MacOS, you can either set it in a `containers.conf` in `~/.config/containers/`. You can
also specify the provider through an environment variable like so:

`$ TMPDIR=/Users/brentbaude CONTAINERS_MACHINE_PROVIDER=libkrun sh run_test.sh /path/to/disk/image`

#### Windows HyperV

Remember that HyperV in Podman machine requires Administrator authority so be certain to open an
administrator powershell.  Then make sure you set the HyperV provider. The simplest approach is using an
environment variable.

`> $Env:CONTAINERS_MACHINE_PROVIDER="hyperv"`

To run the suite, use the Powershell script.

`> .\win_run_test.ps1 c:\Path\To\Disk\Image`
