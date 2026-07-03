#!/usr/bin/env bash
# Deprecated: this script is now a thin shim around scripts/release_app.sh.
# It exists for backwards compatibility with existing CI / muscle memory
# for one release cycle, then will be removed.
#
# New entry point: scripts/release_app.sh
# Lute-server source updates: see docs/on-device-server.md
# (server is bundled in the APK, no separate release script)
#
# The old --with-server flag is silently ignored. The lute-v3 server
# is bundled in the APK and ships with the app release; there is no
# separate server-tarball release step.

set -euo pipefail

echo "================================================================"
echo " DEPRECATION NOTICE"
echo "================================================================"
echo " new_release.sh is now a shim around scripts/release_app.sh."
echo " The --with-server flag is no longer supported here."
echo ""
echo " New flow:"
echo "   - App release:    scripts/release_app.sh [VERSION] [BUILD]"
echo "   - Server source:  re-apply the fork overlay per docs/on-device-server.md"
echo ""
echo " The lute server is bundled in the APK; there is no separate"
echo " server release. See docs/on-device-server.md for details."
echo "================================================================"
echo ""

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "${ROOT_DIR}/scripts/release_app.sh" "$@"
