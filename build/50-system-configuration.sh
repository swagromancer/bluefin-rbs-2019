#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# System Configuration Script
###############################################################################
# This script follows the @ublue-os/bluefin pattern for build scripts.
# It uses set -eoux pipefail for strict error handling and debugging.
###############################################################################

# TODO: Finish configuring services

find /usr/lib/systemd/system/ | grep flatpak

# Enable/disable systemd services
systemctl enable podman.socket
systemctl enable flatpak-preinstall.service

echo "System configuration successful"
