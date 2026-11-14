# Shared settings for build-qemu.sh and package.sh.

QEMU_VERSION=${QEMU_VERSION:-11.1.3}
QEMU_SHA256=${QEMU_SHA256:-5a8289c7940dc77d3873c81a6c29ba3afe1446fc9d36e77fa1658cdbecb84b22}

# Official Broadcom StorCLI release bundle (plain HTTPS, no click-through).
STORCLI_VERSION=007.3811.0000
STORCLI_ZIP=STORCLI_SAS3.5_P39.zip
STORCLI_ZIP_URL=https://docs.broadcom.com/docs-and-downloads/host-bus-adapters/host-bus-adapters-common-files/sas_sata_nvme_12g_p39/$STORCLI_ZIP
STORCLI_ZIP_SHA256=8487c1d099b451b2045e0d615cb081cba354891ee663cb30b621f2f51c94a40d
STORCLI_ZIP_DIR=STORCLI_SAS3.5_P39/univ_viva_cli_rel/Unified_storcli_all_os
STORCLI_DEB=storcli_${STORCLI_VERSION}_all.deb
# Key that signs Broadcom's StorCLI deb and rpm packages.
STORCLI_KEY_FPR=F16EA96DBEEDE53C72FA9D6D43CE04FB871C1697

# Bump when the wrapper, patches or QEMU change for the same StorCLI.
PKG_RELEASE=${PKG_RELEASE:-1}

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK_DIR=${WORK_DIR:-$REPO_DIR/work}
OUT_DIR=${OUT_DIR:-$REPO_DIR/out}
JOBS=${JOBS:-$(nproc)}

arch_vars() {
    DEB_ARCH=$1
    case "$DEB_ARCH" in
    loong64) TRIPLET=loongarch64-linux-gnu RPM_ARCH=loongarch64 ;;
    riscv64) TRIPLET=riscv64-linux-gnu     RPM_ARCH=riscv64 ;;
    *) echo "unsupported architecture: $DEB_ARCH" >&2; exit 1 ;;
    esac
}

# Download (if needed) and verify a file against a pinned sha256.
fetch() {
    local url=$1 dest=$2 sha256=$3
    if [ ! -f "$dest" ]; then
        curl -fL -o "$dest.part" "$url"
        mv "$dest.part" "$dest"
    fi
    echo "$sha256  $dest" | sha256sum -c -
}
