#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Build Initramfs Script
###############################################################################
# This script follows the @ublue-os/bluefin pattern for build scripts.
# It uses set -eoux pipefail for strict error handling and debugging.
###############################################################################

KERNEL_NAME="kernel-longterm"
QUALIFIED_KERNEL="$(rpm -q --queryformat='%{evr}.%{arch}' "${KERNEL_NAME}-core")"

export DRACUT_NO_XATTR=1
/usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible -v --add ostree -f "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
chmod 0600 "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"

echo "Initramfs built successfully"
