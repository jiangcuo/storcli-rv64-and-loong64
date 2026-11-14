#!/bin/sh
# Run the unmodified Broadcom x86_64 storcli64 under a static QEMU
# user-mode emulator.  Installed at the same path as the official binary.

dir=/opt/MegaRAID/storcli/x86_64

if [ "$(uname -m)" = loongarch64 ]; then
    # Old-world (ABI1.0) systems ship kernels older than 5.19, which cannot
    # run new-world (ABI2.0) binaries such as the bundled QEMU.
    kver=$(uname -r)
    major=${kver%%.*}
    minor=${kver#*.}
    minor=${minor%%[!0-9]*}
    if [ "$major" -lt 5 ] || { [ "$major" -eq 5 ] && [ "$minor" -lt 19 ]; }; then
        echo "storcli64: kernel $kver is an old-world (ABI1.0) LoongArch kernel;" >&2
        echo "storcli64: this package supports new-world (ABI2.0, kernel >= 5.19) only." >&2
        exit 1
    fi
fi

exec "$dir/qemu-x86_64" "$dir/storcli64" "$@"
