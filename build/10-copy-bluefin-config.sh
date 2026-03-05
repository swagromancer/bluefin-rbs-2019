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

echo "Bluefin config files copied from @projectbluefin/common successfully"