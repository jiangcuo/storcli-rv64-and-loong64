#!/bin/bash
# Build storcli deb and rpm packages for one architecture.
# Usage: package.sh <loong64|riscv64>
# Needs out/<arch>/qemu-x86_64 from build-qemu.sh; runs inside the
# build/Containerfile image.  Output: out/<arch>/storcli*.{deb,rpm}.
set -euo pipefail

. "$(dirname "$0")/common.sh"
arch_vars "${1:?usage: $0 <loong64|riscv64>}"

qemu_bin="$OUT_DIR/$DEB_ARCH/qemu-x86_64"
qemu_src="$WORK_DIR/qemu-$QEMU_VERSION-$DEB_ARCH"
[ -x "$qemu_bin" ] || { echo "missing $qemu_bin; run build-qemu.sh $DEB_ARCH" >&2; exit 1; }

# Fetch Broadcom's release bundle and check the deb's own signature against
# the signing key pinned in this repository.
fetch "$STORCLI_ZIP_URL" "$WORK_DIR/$STORCLI_ZIP" "$STORCLI_ZIP_SHA256"
upstream="$WORK_DIR/upstream"
rm -rf "$upstream"
mkdir -p "$upstream"
unzip -q -j -d "$upstream" "$WORK_DIR/$STORCLI_ZIP" \
    "$STORCLI_ZIP_DIR/Ubuntu/$STORCLI_DEB" \
    "$STORCLI_ZIP_DIR/Ubuntu/$STORCLI_DEB.sig" \
    "$STORCLI_ZIP_DIR/ThirdPartyLicenseNotice.pdf"
gpg --batch --dearmor -o "$upstream/key.gpg" < "$REPO_DIR/upstream/broadcom-storcli-signing-key.asc"
gpg --batch --show-keys --with-colons "$upstream/key.gpg" | grep -qx "fpr:::::::::$STORCLI_KEY_FPR:"
gpgv --keyring "$upstream/key.gpg" "$upstream/$STORCLI_DEB.sig" "$upstream/$STORCLI_DEB"

stage="$WORK_DIR/stage-$DEB_ARCH"
rm -rf "$stage" "$upstream/deb"
dpkg-deb -x "$upstream/$STORCLI_DEB" "$upstream/deb"

bindir="$stage/opt/MegaRAID/storcli/x86_64"
docdir="$stage/usr/share/doc/storcli"
install -d "$bindir" "$docdir"
install -m 0755 "$upstream/deb/opt/MegaRAID/storcli/storcli64" "$bindir/storcli64"
install -m 0755 "$qemu_bin" "$bindir/qemu-x86_64"
install -m 0755 "$REPO_DIR/packaging/storcli64.sh" "$stage/opt/MegaRAID/storcli/storcli64"
install -m 0644 "$REPO_DIR/upstream/LICENSE-Broadcom-EULA.txt" \
               "$upstream/ThirdPartyLicenseNotice.pdf" \
               "$REPO_DIR/packaging/README.package" "$docdir/"
install -m 0644 "$qemu_src/COPYING" "$docdir/COPYING.qemu"
install -d "$docdir/qemu-patches"
install -m 0644 "$REPO_DIR"/patches/qemu/*.patch "$docdir/qemu-patches/"
cat > "$docdir/qemu-source.txt" <<EOF
QEMU $QEMU_VERSION, built as a static x86_64-linux-user emulator.
Source: https://download.qemu.org/qemu-$QEMU_VERSION.tar.xz
SHA256: $QEMU_SHA256
Local changes are in qemu-patches/ in this directory.
EOF

# The StorCLI binary must stay byte-identical to Broadcom's release.
cmp "$upstream/deb/opt/MegaRAID/storcli/storcli64" "$bindir/storcli64"

version="$STORCLI_VERSION-$PKG_RELEASE"

# deb
debroot="$WORK_DIR/debroot-$DEB_ARCH"
rm -rf "$debroot"
cp -a "$stage" "$debroot"
install -d "$debroot/DEBIAN"
cat > "$debroot/DEBIAN/control" <<EOF
Package: storcli
Version: $version
Section: admin
Priority: optional
Architecture: $DEB_ARCH
Maintainer: LierFang IT Support <itsupport@lierfang.com>
Installed-Size: $(du -sk --exclude=DEBIAN "$debroot" | cut -f1)
Description: Storage Command Line Tool, manages storage controllers
 Runs the unmodified official Broadcom x86_64 storcli64 through a statically
 linked, patched qemu-x86_64 user-mode emulator that passes MegaRAID and
 SG_IO ioctls through to the host kernel.
EOF
dpkg-deb --root-owner-group -Zxz --build "$debroot" \
    "$OUT_DIR/$DEB_ARCH/storcli_${version}_${DEB_ARCH}.deb"

# rpm (v4 format so older rpm-based distributions can install it)
rpmtop="$WORK_DIR/rpmbuild-$DEB_ARCH"
rm -rf "$rpmtop"
rpmbuild -bb --target "$RPM_ARCH-linux" \
    --define "_topdir $rpmtop" \
    --define "_rpmformat 4" \
    --define "_binary_payload w9.xzdio" \
    --define "storcli_version $STORCLI_VERSION" \
    --define "pkg_release $PKG_RELEASE" \
    --define "stage_dir $stage" \
    "$REPO_DIR/packaging/storcli.spec"
cp "$rpmtop"/RPMS/*/storcli-*.rpm "$OUT_DIR/$DEB_ARCH/"

ls -l "$OUT_DIR/$DEB_ARCH"
