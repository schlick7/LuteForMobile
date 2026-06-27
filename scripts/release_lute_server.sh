#!/usr/bin/env bash
# Build and publish the on-device lute-v3 server artifact for Android arm64.
#
# This is the lute-server release. It is intentionally separate from
# scripts/release_app.sh because the server has its own release cadence
# (it tracks upstream LuteOrg/lute-v3, not the Flutter app).
#
# Usage:
#   scripts/release_lute_server.sh                  # defaults to 3.10.1
#   scripts/release_lute_server.sh 3.11.0           # specific lute version
#   scripts/release_lute_server.sh 3.11.0 --skip-build   # publish only
#   scripts/release_lute_server.sh 3.11.0 --skip-publish # build only
#
# Steps:
#   1. (build) Build lute-server-android-arm64-v<ver>.tar.gz + .sha256
#   2. (pin)   Update Settings.luteServerPinnedVersion in the Dart code
#              to match, so the next app build will look for this version.
#   3. (publish) Create a lute-server-v<ver> GitHub release with the
#                tarball + sha256 sidecar.
#
# Requires: docker (for cross-compile), gh (for publishing).

set -euo pipefail

LUTE_VERSION="${1:-3.10.1}"
shift || true

SKIP_BUILD=false
SKIP_PUBLISH=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build)
      SKIP_BUILD=true
      shift
      ;;
    --skip-publish)
      SKIP_PUBLISH=true
      shift
      ;;
    *)
      echo "Unknown arg: $1"
      echo "Usage: scripts/release_lute_server.sh [VERSION] [--skip-build] [--skip-publish]"
      exit 1
      ;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETTINGS_FILE="${ROOT_DIR}/lib/features/settings/models/settings.dart"
DIST_DIR="${ROOT_DIR}/dist"
TARBALL_NAME="lute-server-android-arm64-v${LUTE_VERSION}.tar.gz"
TARBALL="${DIST_DIR}/${TARBALL_NAME}"

# --- 1. Build ------------------------------------------------------------
if [[ "${SKIP_BUILD}" != "true" ]]; then
  echo "=========================================="
  echo "Step 1/3: Build lute-server artifact"
  echo "=========================================="
  bash "${ROOT_DIR}/scripts/build_lute_server.sh" "${LUTE_VERSION}"
else
  echo "Skipping build (--skip-build)"
  if [[ ! -f "${TARBALL}" ]]; then
    echo "Error: ${TARBALL} not found; cannot skip build."
    exit 1
  fi
fi

# --- 2. Pin --------------------------------------------------------------
echo
echo "=========================================="
echo "Step 2/3: Pin luteServerPinnedVersion in settings.dart"
echo "=========================================="
if [[ -f "${SETTINGS_FILE}" ]]; then
  CURRENT_PIN="$(grep -E "static const String luteServerPinnedVersion" \
    "${SETTINGS_FILE}" | sed -E "s/.*'([^']+)'.*/\1/" || true)"
  if [[ "${CURRENT_PIN}" == "${LUTE_VERSION}" ]]; then
    echo "Already pinned to ${LUTE_VERSION}; no change."
  else
    sed -i.bak -E \
      "s|(static const String luteServerPinnedVersion = )'[^']+'|\1'${LUTE_VERSION}'|" \
      "${SETTINGS_FILE}"
    rm -f "${SETTINGS_FILE}.bak"
    echo "Updated: luteServerPinnedVersion '${CURRENT_PIN}' -> '${LUTE_VERSION}'"
    echo "(this file change is not committed automatically)"
  fi
else
  echo "Warning: ${SETTINGS_FILE} not found; skipping pin update."
fi

# --- 3. Publish ----------------------------------------------------------
if [[ "${SKIP_PUBLISH}" != "true" ]]; then
  echo
  echo "=========================================="
  echo "Step 3/3: Publish lute-server to GitHub Releases"
  echo "=========================================="
  bash "${ROOT_DIR}/scripts/publish_lute_server.sh" "${LUTE_VERSION}"
else
  echo "Skipping publish (--skip-publish)"
  echo "Artifact is at: ${TARBALL}"
fi

echo
echo "=========================================="
echo "Lute-server Release Complete"
echo "=========================================="
echo "Version:  ${LUTE_VERSION}"
echo "Artifact: ${TARBALL}"
if [[ "${SKIP_PUBLISH}" != "true" ]]; then
  echo "Release:  https://github.com/schlick7/LuteForMobile/releases/tag/lute-server-v${LUTE_VERSION}"
fi
echo
if [[ "${SKIP_BUILD}" != "true" ]]; then
  echo "Next step: run scripts/release_app.sh to build an APK that uses"
  echo "this lute version. The Dart const has been updated already."
fi
