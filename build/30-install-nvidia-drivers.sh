#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Nvidia Driver Install Script
###############################################################################
# Installs Nvidia drivers from the @ublue-os/akmods-nvidia-open image.
#
# This script follows the @ublue-os/bluefin pattern for build scripts.
# It uses set -eoux pipefail for strict error handling and debugging.
###############################################################################

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/utils/gh-curl.sh

# Exclude the Golang Nvidia Container Toolkit in Fedora Repo
dnf5 config-manager setopt excludepkgs=golang-github-nvidia-container-toolkit

# Install Nvidia RPMs
IMAGE_NAME="bluefin-rbs-2019" RPMFUSION_MIRROR="" AKMODNV_PATH="/ctx/oci/akmods" /ctx/oci/akmods/ublue-os/nvidia-install.sh
rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so
tee /usr/lib/bootc/kargs.d/00-nvidia.toml <<EOF
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
EOF

echo "Nvidia drivers installed successfully"
