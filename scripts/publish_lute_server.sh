#!/usr/bin/env bash
# Publish a lute-server artifact to GitHub Releases.
#
# Usage:
#   scripts/publish_lute_server.sh <LUTE_VERSION>
#   scripts/publish_lute_server.sh 3.10.1
#
# Requires the `gh` CLI to be authenticated. Creates (or replaces) a
# release tagged lute-server-v<version> in the schlick7/LuteForMobile repo.

set -euo pipefail

LUTE_VERSION="${1:-3.10.1}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
TAG="lute-server-v${LUTE_VERSION}"
TARBALL_NAME="lute-server-android-arm64-v${LUTE_VERSION}.tar.gz"
TARBALL="${DIST_DIR}/${TARBALL_NAME}"
SHA="${TARBALL}.sha256"

if [[ ! -f "${TARBALL}" ]]; then
  echo "ERROR: ${TARBALL} not found. Run scripts/build_lute_server.sh first."
  exit 1
fi
if [[ ! -f "${SHA}" ]]; then
  echo "ERROR: ${SHA} not found."
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI not installed. Install from https://cli.github.com/."
  exit 1
fi

# Delete existing release + tag if present (idempotent re-publish).
if gh release view "${TAG}" >/dev/null 2>&1; then
  echo "==> Deleting existing release ${TAG}"
  gh release delete "${TAG}" --yes --cleanup-tag
fi

echo "==> Creating release ${TAG}"
gh release create "${TAG}" \
  --repo schlick7/LuteForMobile \
  --title "lute-server v${LUTE_VERSION}" \
  --notes "Lute v3 server bundle for Android (arm64).

Install via the LuteForMobile app: Settings → Server → On-device → Download.

- lute-v3 version: ${LUTE_VERSION}
- Target: aarch64-linux-android
- Size: $(du -h "${TARBALL}" | cut -f1)
- SHA256: \`$(cat "${SHA}")\`" \
  "${TARBALL}" "${SHA}"

echo ""
echo "Published: https://github.com/schlick7/LuteForMobile/releases/tag/${TAG}"
