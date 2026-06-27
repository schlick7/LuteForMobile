#!/usr/bin/env bash
# Deprecated: this script is now a thin shim around scripts/release_app.sh.
# It exists for backwards compatibility with existing CI / muscle memory
# for one release cycle, then will be removed.
#
# New entry point: scripts/release_app.sh
# Lute-server releases: scripts/release_lute_server.sh
#
# The old --with-server flag is silently ignored. If you need to release
# a lute-server artifact, run scripts/release_lute_server.sh separately.

set -euo pipefail

echo "================================================================"
echo " DEPRECATION NOTICE"
echo "================================================================"
echo " new_release.sh is now a shim around scripts/release_app.sh."
echo " The --with-server flag is no longer supported here."
echo ""
echo " New flow:"
echo "   - App release:    scripts/release_app.sh [VERSION] [BUILD]"
echo "   - Server release: scripts/release_lute_server.sh [LUTE_VERSION]"
echo ""
echo " The lute server has its own release cadence and is published"
echo " independently of the app. See docs/on-device-server.md for details."
echo "================================================================"
echo ""

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "${ROOT_DIR}/scripts/release_app.sh" "$@"
