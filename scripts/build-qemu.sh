#!/bin/bash
# Cross-build a static qemu-x86_64 with the storcli ioctl patches.
# Usage: build-qemu.sh <loong64|riscv64>
# Runs inside the build/Containerfile image; output: out/<arch>/qemu-x86_64.
set -euo pipefail

. "$(dirname "$0")/common.sh"
arch_vars "${1:?usage: $0 <loong64|riscv64>}"

mkdir -p "$WORK_DIR" "$OUT_DIR/$DEB_ARCH"
tarball="$WORK_DIR/qemu-$QEMU_VERSION.tar.xz"
fetch "https://download.qemu.org/qemu-$QEMU_VERSION.tar.xz" "$tarball" "$QEMU_SHA256"

src="$WORK_DIR/qemu-$QEMU_VERSION-$DEB_ARCH"
rm -rf "$src"
mkdir -p "$src"
tar -C "$src" --no-same-owner --strip-components=1 -xf "$tarball"
for p in "$REPO_DIR"/patches/qemu/*.patch; do
    patch -d "$src" -p1 --forward < "$p"
done

export PKG_CONFIG_LIBDIR=/usr/lib/$TRIPLET/pkgconfig:/usr/share/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=/
mkdir -p "$src/build"
cd "$src/build"
../configure \
    --cross-prefix=$TRIPLET- \
    --static \
    --target-list=x86_64-linux-user \
    --disable-system --disable-tools --disable-docs \
    --disable-plugins --disable-debug-info \
    --without-default-features
ninja -j"$JOBS" qemu-x86_64

$TRIPLET-strip -o "$OUT_DIR/$DEB_ARCH/qemu-x86_64" qemu-x86_64
file "$OUT_DIR/$DEB_ARCH/qemu-x86_64"
