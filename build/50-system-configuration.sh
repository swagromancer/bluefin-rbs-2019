#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# System Configuration Script
###############################################################################
# This script follows the @ublue-os/bluefin pattern for build scripts.
# It uses set -eoux pipefail for strict error handling and debugging.
###############################################################################

# TODO: Finish configuring services

# Enable/disable systemd services
systemctl enable podman.socket
systemctl enable flatpak-preinstall.service
systemctl enable ublue-nvidia-flatpak-runtime-sync.service

echo "System configuration successful"
