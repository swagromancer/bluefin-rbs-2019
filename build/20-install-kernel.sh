#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# LTS Kernel Install Script
###############################################################################
# Swaps the kernel out to an LTS version.
#
# On kernel versions above 6.15 the Razer Blade Stealth has an issue where it
# freezes whenever the laptop screen turns off. Most commonly happens when
# suspending, but has been observed in other cases where the screen turns off.
#
# Uncertain if this is a regression in the kernel or something else, needs
# investigation.
#
# Until a later version of the kernel fixes the issue, we'll use 6.12 LTS kernel.
#
# This script follows the @ublue-os/bluefin pattern for build scripts.
# It uses set -eoux pipefail for strict error handling and debugging.
###############################################################################

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/utils/copr-helpers.sh

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
