#!/usr/bin/bash
set -euo pipefail

# Run this script on a fully up to date Fedora 41 VM with SELinux
# in permissive mode and the following tools installed:
# sudo dnf install -y osbuild osbuild-tools osbuild-ostree podman jq xfsprogs e2fsprogs
#
# Invocation of the script would look something like this:
#
# sudo ./custom-coreos-disk-images.sh \
#   --ociarchive /path/to/coreos.ociarchive --platforms qemu
#
# And it will create the output file in the current directory:
# - coreos.ociarchive.x86_64.qemu.qcow2
#
# Passing multple platforms will yield multiple disk images:
#
# sudo ./custom-coreos-disk-images.sh \
#   --ociarchive /path/to/coreos.ociarchive --platforms qemu,metal
#
# - coreos-qemu.x86_64.qcow2
# - coreos-metal.x86_64.raw

ARCH=$(arch)

# A list of supported platforms and the filename suffix of the main
# artifact that platform produces.
declare -A SUPPORTED_PLATFORMS=(
    ['applehv']='raw'
    ['gcp']='tar.gz'
    ['hyperv']='vhdx'
    ['metal4k']='raw'
    ['metal']='raw'
    ['qemu']='qcow2'
)

check_rpm() {
    req=$1
    if ! rpm -q "$req" &>/dev/null; then
        echo "No $req. Can't continue" 1>&2
        return 1
    fi
}

check_rpms() {
    reqs=(osbuild osbuild-tools osbuild-ostree jq xfsprogs e2fsprogs)
    for req in "${reqs[@]}"; do
        check_rpm "$req"
    done
}

main() {

    # Call getopt to validate the provided input.
    options=$(getopt --options - --longoptions 'imgref:,ociarchive:,osname:,platforms:,metal-image-size:,cloud-image-size:,extra-kargs:' -- "$@")
    if [ $? -ne 0 ]; then
        echo "Incorrect options provided"
        exit 1
    fi
    eval set -- "$options"
    while true; do
        case "$1" in
        --cloud-image-size)
            shift # The arg is next in position args
            cloud_image_size=$1
            ;;
        --extra-kargs)
            shift # The arg is next in position args
            extra_kargs="$1"
            ;;
        --imgref)
            shift # The arg is next in position args
            imgref=$1
            ;;
        --metal-image-size)
            shift # The arg is next in position args
            metal_image_size=$1
            ;;
        --ociarchive)
            shift # The arg is next in position args
            ociarchive=$1
            ;;
        --osname)
            shift # The arg is next in position args
            osname=$1
            if [ "$osname" != rhcos ] && [ "$osname" != fedora-coreos ]; then
                echo "--osname must be rhcos or fedora-coreos" >&2
                exit 1
            fi
            ;;
        --platforms)
            shift # The arg is next in position args
            # Split the comma separated string of platforms into an array
            IFS=, read -ra platforms <<<"$1"
            ;;
        --)
            shift
            break
            ;;
        esac
        shift
    done

    # Make sure RPMs are installed
    check_rpms
    # Make sure SELinux is permissive
    if [ "$(getenforce)" != "Permissive" ]; then
        echo "SELinux needs to be set to permissive mode"
        exit 1
    fi
    # Make sure we are effectively `root`
    if [ $UID -ne 0 ]; then
        echo "OSBuild needs to run with root permissions"
        exit 1
    fi
    # Make sure the given file exists
    if [ ! -f $ociarchive ]; then
        echo "need to pass in the path to .ociarchive file"
        exit 1
    fi
    # Convert it to an absolute path
    ociarchive=$(readlink -f $ociarchive)

    # Let's set the imgref. If no --imgref was provided then for cosmetic
    # purposes let's set a sane looking one.
    imgref="${imgref:-ostree-image-signed:oci-archive:/$(basename "${ociarchive}")}"

    # Let's default to `rhcos` for the OS Name for backwards compat
    osname="${osname:-rhcos}"

    # FCOS/RHCOS have different default disk image sizes
    # In the future should pull this from the container image
    # (/usr/share/coreos-assembler/image.json)
    if [ -z "${cloud_image_size:-}" ]; then
        cloud_image_size=10240 # FCOS
        if [ $osname == 'rhcos' ]; then
            cloud_image_size=16384 # RHCOS
        fi
    fi

    # Default Metal Image Size
    metal_image_size="${metal_image_size:-3072}"

    # Default kernel arguments are different for FCOS/RHCOS
    if [ -z "${extra_kargs:-}" ]; then
        extra_kargs="" # RHCOS
        if [ "$osname" == 'fedora-coreos' ]; then
            extra_kargs="mitigations=auto,nosmt" # FCOS
        fi
    fi

    # Make a local tmpdir and outdir
    tmpdir=$(mktemp -d ./tmp-osbuild-XXX)
    outdir="${tmpdir}/out"
    mkdir $outdir

    # Freeze on specific version for now to increase stability.
    #gitreporef="main"
    gitreporef="a13cf77d37aa4c57922e83f3706630ae7e33ac4e"
    gitrepotld="https://raw.githubusercontent.com/coreos/coreos-assembler/${gitreporef}/"
    pushd "${tmpdir}"
    curl -LO --fail "${gitrepotld}/src/runvm-osbuild"
    chmod +x runvm-osbuild
    for manifest in "coreos.osbuild.${ARCH}.mpp.yaml" platform.{applehv,gcp,hyperv,live,metal,qemu,qemu-secex}.ipp.yaml; do
        curl -LO --fail "${gitrepotld}/src/osbuild-manifests/${manifest}"
    done
    # Temporarily chop off the last two lines from "coreos.osbuild.${ARCH}.mpp.yaml"
    # that performs inclusion of the `live` platform added in [1]. The stages
    # haven't been merged upstream yet and won't be in the installed OSBuild
    # RPMs yet.
    # [1] https://github.com/coreos/coreos-assembler/pull/3976
    mv "coreos.osbuild.${ARCH}.mpp.yaml"{,.orig}
    head -n -2 "coreos.osbuild.${ARCH}.mpp.yaml.orig" > "coreos.osbuild.${ARCH}.mpp.yaml"
    popd


    # - rootfs size is only used on s390x secex so we pass "0" here
    # - extra-kargs from image.yaml/image.json is currently empty
    #   on RHCOS but we may want to start picking it up from inside
    #   the container image (/usr/share/coreos-assembler/image.json)
    #   in the future. https://github.com/openshift/os/blob/master/image.yaml
    runvm_osbuild_config_json="${tmpdir}/runvm-osbuild-config.json"
    cat > "${runvm_osbuild_config_json}" << EOF
{
    "artifact-name-prefix": "$(basename -s .ociarchive $ociarchive)",
	"osname": "${osname}",
	"deploy-via-container": "true",
	"ostree-container": "${ociarchive}",
	"container-imgref": "${imgref}",
	"metal-image-size": "${metal_image_size}",
	"cloud-image-size": "${cloud_image_size}",
	"rootfs-size": "0",
	"extra-kargs-string": "${extra_kargs}"
}
EOF
    "${tmpdir}/runvm-osbuild"                             \
        --config "${runvm_osbuild_config_json}"           \
        --mpp "${tmpdir}/coreos.osbuild.${ARCH}.mpp.yaml" \
        --outdir "${outdir}"                              \
        --platforms "$(IFS=,; echo "${platforms[*]}")"

    for platform in "${platforms[@]}"; do
        # Set the filename of the artifact and the local image path
        # where from the OSBuild out directory where it resides.
        suffix="${SUPPORTED_PLATFORMS[$platform]}"
        imgname=$(basename -s .ociarchive $ociarchive)-${platform}.${ARCH}.${suffix}
        imgpath="${outdir}/${platform}/${imgname}"
        mv "${imgpath}" ./
        echo "Created $platform image file at: ${imgname}"
    done

    rm -rf "${outdir}"; rm -f "${tmpdir}"/*; rmdir "${tmpdir}" # Cleanup
}

main "$@"
