#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Copy Bluefin Configs Script
###############################################################################
# Copies configuration files from other @projectbluefin container images.
#
# This script follows the @ublue-os/bluefin pattern for build scripts.
# It uses set -eoux pipefail for strict error handling and debugging.
###############################################################################

# Copy just files from @projectbluefin/common (includes 00-entry.just which imports 60-custom.just)
mkdir -p /usr/share/ublue-os/just/
cp -r /ctx/oci/common/bluefin/usr/share/ublue-os/just/* /usr/share/ublue-os/just/

# Copy shared /usr/lib files from @projectbluefin/common (excluding modeprobe.d as it has an amd conf file we don't need)
find /ctx/oci/common/shared/usr/lib/* -maxdepth 0 -type d \! -name modprobe.d -exec sh -c 'for f do cp -r $f/* /usr/lib/${f##*/}/;done' sh {} +

# Copy bluefin systemd files from #projectbluefin/common
cp -r /ctx/oci/common/bluefin/usr/lib/systemd/* /usr/lib/systemd/

# Copy Nvidia config files from @projectbluefin/common (includes workaround for https://github.com/flatpak/flatpak/issues/3907)
cp -r /ctx/oci/common/nvidia/usr/* /usr/

# Copy uutils profile script from @projectbluefin/common
cp -r /ctx/oci/common/bluefin/etc/profile.d/uutils.sh /etc/profile.d/

# Copy Homebrew tarball and config files from @ublue-os/brew
cp -r /ctx/oci/brew/* /

echo "Bluefin config files copied from @projectbluefin/common successfully"
