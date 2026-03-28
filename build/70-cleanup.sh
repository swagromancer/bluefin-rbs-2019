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

# Cleanup /var
find /var/* -maxdepth 0 -type d \! -name cache \! -name log -exec rm -fr {} \;
find /var/cache/* -maxdepth 0 -type d \! -name libdnf5 -exec rm -rf {} \;

# Cleanup /run directories that make bootc container lint unhappy when they exist
rm -rf /run/dnf
rm -rf /run/selinux-policy

# Recreate the /boot directory since things in here _also_ make bootc container lint unhappy
# shellcheck disable=SC2114
rm -rf /boot && mkdir -p /boot

echo "Cleanup successful"
