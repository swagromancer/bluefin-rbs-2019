#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Main Build Script
###############################################################################
# This script follows the @ublue-os/bluefin pattern for build scripts.
# It uses set -eoux pipefail for strict error handling and debugging.
###############################################################################

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

# Enable nullglob for all glob operations to prevent failures on empty matches
shopt -s nullglob

echo "::group:: Copy Bluefin Config from Common"

# Copy just files from @projectbluefin/common (includes 00-entry.just which imports 60-custom.just)
mkdir -p /usr/share/ublue-os/just/
shopt -s nullglob
cp -r /ctx/oci/common/bluefin/usr/share/ublue-os/just/* /usr/share/ublue-os/just/
shopt -u nullglob

echo "::endgroup::"

echo "::group:: Copy Custom Files"

# Copy Brewfiles to standard location
mkdir -p /usr/share/ublue-os/homebrew/
cp /ctx/custom/brew/*.Brewfile /usr/share/ublue-os/homebrew/

# Consolidate Just Files
find /ctx/custom/ujust -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /usr/share/ublue-os/just/60-custom.just

# Copy Flatpak preinstall files
mkdir -p /etc/flatpak/preinstall.d/
cp /ctx/custom/flatpaks/*.preinstall /etc/flatpak/preinstall.d/

echo "::endgroup::"

# On kernel versions above 6.15 there is a bug where the system will freeze whenever the system suspends,
# or whenever the laptop screen turns off. The 6.15 kernel is EoL, so use the 6.12 LTS kernel instead.
echo "::group:: Switch to LTS Kernel"

for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra; do
    rpm --erase $pkg --nodeps
done

# On F43, a new problem manifests where during kernel install, dracut errors and fails

# create a shim to bypass kernel install triggering dracut/rpm-ostree
# seems to be minimal impact, but allows progress on build
cd /usr/lib/kernel/install.d \
&& mv 05-rpmostree.install 05-rpmostree.install.bak \
&& mv 50-dracut.install 50-dracut.install.bak \
&& printf '%s\n' '#!/bin/sh' 'exit 0' > 05-rpmostree.install \
&& printf '%s\n' '#!/bin/sh' 'exit 0' > 50-dracut.install \
&& chmod +x  05-rpmostree.install 50-dracut.install

# Derive the LTS kernel version from the Nvidia akmod built version
KERNEL_LTS_VERSION=$(cat /ctx/oci/nvidia-rpms/kmods/nvidia-vars | grep KERNEL_VERSION | sed -e 's/^.*=//')

KERNEL_LTS_PACKAGES=(
    kernel-longterm-"${KERNEL_LTS_VERSION}"
    kernel-longterm-core-"${KERNEL_LTS_VERSION}"
    kernel-longterm-modules-"${KERNEL_LTS_VERSION}"
    kernel-longterm-modules-core-"${KERNEL_LTS_VERSION}"
    kernel-longterm-modules-extra-"${KERNEL_LTS_VERSION}"
)

copr_install_isolated "kwizart/kernel-longterm-6.12" "${KERNEL_LTS_PACKAGES[@]}"

# restore kernel install
mv -f 05-rpmostree.install.bak 05-rpmostree.install \
&& mv -f 50-dracut.install.bak 50-dracut.install
cd -

dnf5 versionlock add "${KERNEL_LTS_PACKAGES[@]}"

echo "LTS Kernel installed successfully"
echo "::endgroup::"

echo "::group:: Install Nvidia Drivers"

# Exclude the Golang Nvidia Container Toolkit in Fedora Repo
dnf5 config-manager setopt excludepkgs=golang-github-nvidia-container-toolkit

# Install Nvidia RPMs
curl -L "https://raw.githubusercontent.com/ublue-os/main/main/build_files/nvidia-install.sh" --create-dirs -o /tmp/nvidia-install.sh
chmod +x /tmp/nvidia-install.sh
IMAGE_NAME="bluefin-rbs-2019" RPMFUSION_MIRROR="" AKMODNV_PATH="/ctx/oci/nvidia-rpms" /tmp/nvidia-install.sh
rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so
tee /usr/lib/bootc/kargs.d/00-nvidia.toml <<EOF
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
EOF

echo "Nvidia installed successfully"
echo "::endgroup::"

echo "::group:: Install Packages"

# Install packages using dnf5
# Example: dnf5 install -y tmux

# Example using COPR with isolated pattern:
# copr_install_isolated "ublue-os/staging" package-name

# Base packages from Fedora repos - common to all versions
readarray -t INCLUDED_PACKAGES < <(jq -r "[(.base.include)] \
                            | sort | unique[]" /ctx/build/packages.json)

# Install all Fedora packages (bulk - safe from COPR injection)
echo "Installing ${#INCLUDED_PACKAGES[@]} packages from Fedora repos..."
dnf5 -y install "${INCLUDED_PACKAGES[@]}"

dnf5 config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
dnf5 config-manager setopt tailscale-stable.enabled=0
dnf5 -y install --enablerepo='tailscale-stable' tailscale

# From che/nerd-fonts
copr_install_isolated "che/nerd-fonts" "nerd-fonts"

# From ublue-os/packages
copr_install_isolated "ublue-os/packages" "uupd"

# Packages to exclude
readarray -t EXCLUDED_PACKAGES < <(jq -r "[(.base.exclude)] \
                            | sort | unique[]" /ctx/build/packages.json)

# Remove excluded packages if they are installed
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    readarray -t INSTALLED_EXCLUDED < <(rpm -qa --queryformat='%{NAME}\n' "${EXCLUDED_PACKAGES[@]}" 2>/dev/null || true)
    if [[ "${#INSTALLED_EXCLUDED[@]}" -gt 0 ]]; then
        echo "Removing ${#INCLUDED_PACKAGES[@]} packages..."
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

echo "::endgroup::"

echo "::group:: System Configuration"

# Enable/disable systemd services
systemctl enable podman.socket
# Example: systemctl mask unwanted-service

echo "::endgroup::"

# Restore default glob behavior
shopt -u nullglob

echo "Custom build complete!"
