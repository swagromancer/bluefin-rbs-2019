#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Kernel Install Script
###############################################################################
# Install kernel from mounted akmods containers.
#
# This script follows the @ublue-os/bluefin pattern for build scripts.
# It uses set -eoux pipefail for strict error handling and debugging.
###############################################################################

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/utils/copr-helpers.sh

# On kernel versions above 6.15 the Razer Blade Stealth 2019 has an issue where it
# freezes whenever the laptop screen turns off. Most commonly happens when
# suspending, but has been observed in other cases where the screen turns off.
#
# Uncertain if this is a regression in the kernel or something else, needs
# investigation.
#
# Until a later version of the kernel fixes the issue, we'll use kernel-longterm.
KERNEL_NAME="kernel-longterm"

for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra; do
    rpm --erase $pkg --nodeps
done

# create a shim to bypass kernel install triggering dracut/rpm-ostree
# seems to be minimal impact, but allows progress on build
cd /usr/lib/kernel/install.d \
&& mv 05-rpmostree.install 05-rpmostree.install.bak \
&& mv 50-dracut.install 50-dracut.install.bak \
&& printf '%s\n' '#!/bin/sh' 'exit 0' > 05-rpmostree.install \
&& printf '%s\n' '#!/bin/sh' 'exit 0' > 50-dracut.install \
&& chmod +x  05-rpmostree.install 50-dracut.install

# Install kernel from mounted /tmp/kernel-rpms (provided by Containerfile akmods mounts)
echo "Installing kernel from mounted kernel-rpms..."

# Extract kernel version from the first kernel rpm filename
CACHED_VERSION=$(find /ctx/oci/kernel-rpms \
	-maxdepth 1 \
	-regextype posix-extended \
	-iregex ".*/${KERNEL_NAME}-[[:digit:]].*.rpm" \
	-type f \
	-printf "%f" \
	-quit | \
	sed -E "s/^${KERNEL_NAME}-//;s/\.rpm$//")

if [[ -z "$CACHED_VERSION" ]]; then
  echo "ERROR: Could not detect kernel version from /ctx/oci/kernel-rpms"
  ls -la /ctx/oci/kernel-rpms
  exit 1
fi

echo "Detected kernel version: ${CACHED_VERSION}"

INSTALL_PKGS=(
    "${KERNEL_NAME}"
    "${KERNEL_NAME}"-core
    "${KERNEL_NAME}"-modules
    "${KERNEL_NAME}"-modules-core
    "${KERNEL_NAME}"-modules-extra
)

RPM_NAMES=()
for pkg in "${INSTALL_PKGS[@]}"; do
  RPM_NAMES+=("/ctx/oci/kernel-rpms/$pkg-$CACHED_VERSION.rpm")
done

dnf5 -y install "${RPM_NAMES[@]}"

# restore kernel install
mv -f 05-rpmostree.install.bak 05-rpmostree.install \
&& mv -f 50-dracut.install.bak 50-dracut.install
cd -

dnf5 versionlock add "${INSTALL_PKGS[@]}"

echo "LTS Kernel installed successfully"
