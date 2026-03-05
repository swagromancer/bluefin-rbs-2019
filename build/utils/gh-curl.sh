#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# GitHub Curl Script
###############################################################################
# Wrapper for curling Github
#
# This script follows the @ublue-os/bluefin pattern for build scripts.
# It uses set -eoux pipefail for strict error handling and debugging.
###############################################################################

ghcurl() {
	# Check for GITHUB_TOKEN in /run/secrets/GITHUB_TOKEN (Podman secret mount)
	if [[ -f /run/secrets/GITHUB_TOKEN ]]; then
		GITHUB_TOKEN=$(< /run/secrets/GITHUB_TOKEN)
		echo "Using GITHUB_TOKEN from /run/secrets/GITHUB_TOKEN for authentication." >&2
		AUTH_HEADER="Authorization: Bearer $GITHUB_TOKEN"
	else
		echo "GITHUB_TOKEN secret not found. Using unauthenticated requests." >&2
		AUTH_HEADER=""
	fi

	URL="$1"
	shift
	OPTIONS=("$@")

	if [[ -n "$AUTH_HEADER" ]]; then
		curl -sSL -H "$AUTH_HEADER" "${OPTIONS[@]}" "$URL"
	else
		curl -sSL "${OPTIONS[@]}" "$URL"
	fi
}
