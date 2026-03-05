#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Package Install Script
###############################################################################
# Installs packages from Fedora and COPR repos.
#
# This script follows the @ublue-os/bluefin pattern for build scripts.
# It uses set -eoux pipefail for strict error handling and debugging.
###############################################################################

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/utils/copr-helpers.sh

# Validate packages.json before attempting to parse it
# This ensures builds fail fast if the JSON is malformed
if ! jq empty /ctx/build/packages.json 2>/dev/null; then
    echo "ERROR: packages.json contains syntax errors and cannot be parsed" >&2
    echo "Please fix the JSON syntax before building" >&2
    exit 1
fi

# Base packages from Fedora repos - common to all versions
readarray -t INCLUDED_PACKAGES < <(jq -r ".base.include | sort | unique[]" /ctx/build/packages.json)

# Install all Fedora packages (bulk - safe from COPR injection)
if [[ "${#INCLUDED_PACKAGES[@]}" -gt 0 ]]; then
	echo "Installing ${#INCLUDED_PACKAGES[@]} packages from Fedora repos..."
    dnf5 -y install "${INCLUDED_PACKAGES[@]}"
else
    echo "No packages to install."

fi

dnf5 config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
dnf5 config-manager setopt tailscale-stable.enabled=0
dnf5 -y install --enablerepo='tailscale-stable' tailscale

# From che/nerd-fonts
copr_install_isolated "che/nerd-fonts" "nerd-fonts"

# From ublue-os/packages
copr_install_isolated "ublue-os/packages" "uupd"

# Packages to exclude
readarray -t EXCLUDED_PACKAGES < <(jq -r ".base.exclude | sort | unique[]" /ctx/build/packages.json)

# Remove excluded packages if they are installed
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    readarray -t INSTALLED_EXCLUDED < <(rpm -qa --queryformat='%{NAME}\n' "${EXCLUDED_PACKAGES[@]}" 2>/dev/null || true)
    if [[ "${#INSTALLED_EXCLUDED[@]}" -gt 0 ]]; then
        dnf5 -y remove "${INSTALLED_EXCLUDED[@]}"
    else
        echo "No excluded packages found to remove."
    fi
fi

# Fix for ID in fwupd
dnf5 -y copr enable ublue-os/staging
dnf5 -y copr disable ublue-os/staging
dnf5 -y swap \
    --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
    fwupd fwupd

echo "Packages installed successfully"
