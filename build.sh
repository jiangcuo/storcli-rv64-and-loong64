#!/bin/bash
# Build static QEMU and storcli deb/rpm packages on an x86_64 host.
# Usage: ./build.sh [loong64] [riscv64]   (default: both)
set -euo pipefail

cd "$(dirname "$0")"
runtime=${CONTAINER_RUNTIME:-$(command -v podman || command -v docker)}
image=storcli-cross
arches=("$@")
[ ${#arches[@]} -gt 0 ] || arches=(loong64 riscv64)

"$runtime" build -t "$image" -f build/Containerfile build
for arch in "${arches[@]}"; do
    "$runtime" run --rm -v "$PWD":/src:Z -w /src "$image" \
        bash -c "./scripts/build-qemu.sh $arch && ./scripts/package.sh $arch"
done
