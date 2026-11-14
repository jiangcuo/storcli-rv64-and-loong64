# Repackages prebuilt files staged by scripts/package.sh; nothing is compiled.
%global debug_package %{nil}
%global __os_install_post %{nil}
%global _build_id_links none

Name:           storcli
Version:        %{storcli_version}
Release:        %{pkg_release}
Summary:        Storage Command Line Tool (x86_64 StorCLI under QEMU user-mode)
License:        Broadcom Inc. (StorCLI); GPL-2.0-only (QEMU)
URL:            https://www.broadcom.com
AutoReqProv:    no
Requires:       /bin/sh

%description
storcli is used to manage storage controllers.

This package runs the unmodified official Broadcom x86_64 storcli64 on
%{_target_cpu} through a statically linked, patched qemu-x86_64 user-mode
emulator that passes MegaRAID and SG_IO ioctls through to the host kernel.

%install
cp -a %{stage_dir}/. %{buildroot}/

%files
%dir /opt/MegaRAID
%dir /opt/MegaRAID/storcli
%dir /opt/MegaRAID/storcli/x86_64
/opt/MegaRAID/storcli/storcli64
/opt/MegaRAID/storcli/x86_64/storcli64
/opt/MegaRAID/storcli/x86_64/qemu-x86_64
%doc /usr/share/doc/storcli
