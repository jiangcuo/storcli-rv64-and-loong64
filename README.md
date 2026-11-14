# storcli-rv64-and-loong64

Broadcom StorCLI deb/rpm packages for LoongArch64 (new world) and RISC-V 64.

The packages contain Broadcom's official, unmodified x86_64 `storcli64`, run
through a statically linked `qemu-x86_64` patched for MegaRAID and SG_IO ioctl
passthrough.

## How it is built

On an x86_64 host with podman or docker:

```bash
./build.sh
```

The script downloads StorCLI from Broadcom and verifies its signature,
cross-compiles the static QEMU, and writes the packages to `out/<arch>/`.
Pushing a tag makes GitHub Actions build them and publish a release.
