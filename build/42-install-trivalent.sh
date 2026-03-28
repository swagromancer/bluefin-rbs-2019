#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Trivalent Install Script
###############################################################################
# Installs the Trivalent browser.
# Trivalent is a security-focused, Chromium-based browser inspired by Vanadium.
#
# This script follows the @ublue-os/bluefin pattern for build scripts.
# It uses set -eoux pipefail for strict error handling and debugging.
###############################################################################

# Add Secureblue RPM repository
cat > /etc/yum.repos.d/secureblue.repo << 'EOF'
[secureblue]
name=secureblue
baseurl=https://repo.secureblue.dev
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://repo.secureblue.dev/secureblue.gpg
EOF

# Install Trivalent
dnf5 install -y trivalent

# Clean up repo file
rm -f /etc/yum.repos.d/secureblue.repo

echo "Trivalent installed successfully"
