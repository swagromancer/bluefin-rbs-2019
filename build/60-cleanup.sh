#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Cleanup Script
###############################################################################
# This script follows the @ublue-os/bluefin pattern for build scripts.
# It uses set -eoux pipefail for strict error handling and debugging.
###############################################################################

# Cleanup package manager
dnf5 clean all

# systemctl mask flatpak-add-fedora-repos.service
# rm -f /usr/lib/systemd/system/flatpak-add-fedora-repos.service

rm -rf /.gitkeep

# Cleanup /var
find /var/* -maxdepth 0 -type d \! -name cache \! -name log -exec rm -fr {} \;

# Cleanup /run
find /run/* -maxdepth 0 -type d -exec rm -fr {} \;

# Recreate the /boot directory since bootc container lint doesn't like when things are in it
# shellcheck disable=SC2114
rm -rf /boot && mkdir -p /boot

echo "Cleanup successful"
