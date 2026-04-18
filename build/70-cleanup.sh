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
find /var/* -maxdepth 0 -type d \! -name cache \! -name log -exec rm -rf {} \;
find /var/cache/* -maxdepth 0 -type d \! -name libdnf5 -exec rm -rf {} \;

# Recreate the /boot directory since things in here make bootc container lint unhappy
# shellcheck disable=SC2114
rm -rf /boot && mkdir -p /boot

echo "Cleanup successful"
