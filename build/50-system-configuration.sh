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
systemctl --global enable podman-auto-update.timer
systemctl enable podman.socket

systemctl enable flatpak-preinstall.service
systemctl enable ublue-nvidia-flatpak-runtime-sync.service

systemctl enable dev-groups.service
systemctl enable swtpm-workaround.service
systemctl enable libvirt-workaround.service

systemctl enable dconf-update.service
systemctl enable uupd.timer

systemctl disable flatpak-add-fedora-repos.service
systemctl disable rpm-ostreed-automatic.timer

# Enable Homebrew services copied from @ublue-os/brew
systemctl preset brew-setup.service

echo "System configuration successful"
