#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# GNOME Shell Extension Build Script
###############################################################################
# Builds GNOME shell extensions that aren't available in Fedora RPM repos for
# system-wide use.
#
# This script follows the @ublue-os/bluefin pattern for build scripts.
# It uses set -eoux pipefail for strict error handling and debugging.
###############################################################################

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/utils/gh-curl.sh

# Install tooling
dnf5 -y install glib2-devel meson sassc cmake dbus-devel

# Logo Menu
glib-compile-schemas --strict /usr/share/gnome-shell/extensions/logomenu@aryan_k/schemas

# Search Light
glib-compile-schemas --strict /usr/share/gnome-shell/extensions/search-light@icedman.github.com/schemas

# Recompile
rm /usr/share/glib-2.0/schemas/gschemas.compiled
glib-compile-schemas /usr/share/glib-2.0/schemas

# Cleanup
dnf5 -y remove glib2-devel meson sassc cmake dbus-devel

echo "Custom setup ran successfully"