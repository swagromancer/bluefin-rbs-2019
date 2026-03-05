#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Main Build Script
###############################################################################
# This script follows the @ublue-os/bluefin pattern for build scripts.
# It uses set -eoux pipefail for strict error handling and debugging.
###############################################################################

# Enable nullglob for all glob operations to prevent failures on empty matches
shopt -s nullglob

# Complex "find" expression to run build scripts in numerical order
# Allows us to numerically sort scripts by stuff like "01-packages.sh" or whatever
find "$(realpath "$(dirname "$0")")" -maxdepth 1 -regextype posix-extended -iregex ".*/[[:digit:]]{2}-.*.sh" -type f -print0 | sort --zero-terminated --sort=human-numeric | while IFS= read -r -d $'\0' script ; do
	echo "::group:: $(basename "$script")"
	bash "$(realpath "$script")"
	echo "::endgroup::"
done

# Restore default glob behavior
shopt -u nullglob

echo "Custom build complete!"
