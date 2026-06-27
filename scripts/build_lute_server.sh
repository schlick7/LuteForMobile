#!/usr/bin/env bash
# Build a standalone lute-v3 server artifact for Android arm64.
#
# Produces:
#   dist/lute-server-android-arm64-v<version>.tar.gz
#   dist/lute-server-android-arm64-v<version>.tar.gz.sha256
#
# Requirements on the build host:
#   - Docker with binfmt support for aarch64 (see setup notes below)
#   - 3-5 GB free disk
#
# Usage:
#   scripts/build_lute_server.sh                  # defaults to 3.10.1
#   scripts/build_lute_server.sh 3.11.0
#
# First-time setup: the host needs qemu registered with binfmt_misc so
# Docker can run arm64 images. Run this once:
#
#   sudo docker run --rm --privileged tonistiigi/binfmt --install all
#
# Without that, the manylinux entrypoint fails with "exec format error".

set -euo pipefail

LUTE_VERSION="${1:-3.10.1}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build/lute-server"
DIST_DIR="${ROOT_DIR}/dist"
TARBALL_NAME="lute-server-android-arm64-v${LUTE_VERSION}.tar.gz"
TARBALL="${DIST_DIR}/${TARBALL_NAME}"

# Build script that runs inside the container. We pass this as a file
# (not a heredoc) so qemu emulation on the host doesn't get confused by
# the script content while transferring.
CONTAINER_SCRIPT="$(mktemp /tmp/opencode/lute-build-XXXXXX.sh)"
mkdir -p "$(dirname "${CONTAINER_SCRIPT}")"
cat > "${CONTAINER_SCRIPT}" <<'BASH'
#!/bin/bash
# This script runs inside the manylinux2014_aarch64 container.
set -ex

PY_VERSION="3.11"
PY_BIN_DIR=$(ls -d /opt/_internal/cpython-${PY_VERSION}.* 2>/dev/null | head -1 || true)
if [[ -z "${PY_BIN_DIR}" ]]; then
  echo "ERROR: Python ${PY_VERSION} not found in this image."
  echo "Available interpreters:"
  ls /opt/_internal/ 2>/dev/null || true
  exit 1
fi
echo "Using Python from ${PY_BIN_DIR}"

DEST=/out/build
rm -rf "${DEST}"
mkdir -p "${DEST}/python"

# Copy Python install, strip test/bytecode to save space.
cp -a "${PY_BIN_DIR}/." "${DEST}/python/"
rm -rf "${DEST}/python/lib/python${PY_VERSION}/test"
find "${DEST}/python" -name __pycache__ -type d -exec rm -rf {} + 2>/dev/null || true

# Bootstrap pip.
"${DEST}/python/bin/python${PY_VERSION}" -m ensurepip --upgrade 2>&1 | tail -3

# Install lute runtime deps into lute-deps/. Skip natto-py: it's a C
# extension for MeCab that can't build for aarch64-linux-android and
# isn't bundled in v1.
mkdir -p "${DEST}/lute-deps"
DEPS=(
  "Flask-SQLAlchemy>=3.1.1,<4"
  "Flask-WTF>=1.2.1,<2"
  "jaconv>=0.3.4,<1"
  "platformdirs>=3.10.0,<4"
  "requests>=2.31.0,<3"
  "beautifulsoup4>=4.12.2,<5"
  "PyYAML>=6.0.1,<7"
  "toml>=0.10.2,<1"
  "waitress>=2.1.2,<3"
  "openepub>=0.0.8,<1"
  "pyparsing>=3.1.4"
  "pypdf>=3.17.4"
  "subtitle-parser>=1.3.0"
  "ahocorapy>=1.6.2"
)
"${DEST}/python/bin/pip${PY_VERSION}" install \
  --no-cache-dir \
  --target "${DEST}/lute-deps" \
  "${DEPS[@]}" 2>&1 | tail -10

# Copy lute package itself on top of lute-deps/lute/ so it's importable.
cp -a /src/lute/. "${DEST}/lute-deps/lute/"

# Launcher.
cat > "${DEST}/lute-server" <<'EOF'
#!/bin/sh
# Embedded lute-v3 launcher.
# Usage: lute-server --port N --datapath DIR [--local]
HERE="$(cd "$(dirname "$0")" && pwd)"
PY="${HERE}/python/bin/python3.11"
export PYTHONPATH="${HERE}/lute-deps:${PYTHONPATH:-}"
export HOME="${HOME:-/data/data/com.schlick7.luteformobile/files}"
exec "${PY}" -m lute.main "$@"
EOF
chmod +x "${DEST}/lute-server"

# Make the build output readable by the host user.
chown -R $(stat -c %u:%g /src) "${DEST}"

echo "Container build complete."
ls -la "${DEST}"
BASH
chmod +x "${CONTAINER_SCRIPT}"

# --- 1. Clean previous build -------------------------------------------
echo "==> [1/4] Cleaning previous build artifacts"
if [[ -d "${BUILD_DIR}" ]]; then
  rm -rf "${BUILD_DIR}"
fi
if [[ -d "${DIST_DIR}" ]]; then
  rm -rf "${DIST_DIR}"
fi
mkdir -p "${DIST_DIR}"

# --- 2. Clone upstream -------------------------------------------------
echo "==> [2/4] Cloning LuteOrg/lute-v3 at tag ${LUTE_VERSION}"
git clone --depth 1 --branch "${LUTE_VERSION}" \
  https://github.com/LuteOrg/lute-v3.git "${BUILD_DIR}"

# --- 3. Build inside container ----------------------------------------
echo "==> [3/4] Building arm64 artifact (this takes 5-10 minutes under qemu emulation)"
docker run --rm --platform linux/arm64 \
  -v "${BUILD_DIR}:/src:ro" \
  -v "${DIST_DIR}:/out" \
  -v "${CONTAINER_SCRIPT}:/build.sh:ro" \
  quay.io/pypa/manylinux2014_aarch64 \
  bash /build.sh

# --- 4. Tar + hash ----------------------------------------------------
echo "==> [4/4] Packaging artifact"
if [[ ! -d "${DIST_DIR}/build" ]]; then
  echo "ERROR: container did not produce ${DIST_DIR}/build"
  exit 1
fi
cd "${DIST_DIR}"
tar -czf "${TARBALL_NAME}" -C build .
cd "${ROOT_DIR}"
rm -rf "${DIST_DIR}/build"

sha256sum "${TARBALL}" | awk '{print $1}' > "${TARBALL}.sha256"

rm -f "${CONTAINER_SCRIPT}"

echo ""
echo "Built: ${TARBALL}"
echo "SHA256: $(cat "${TARBALL}.sha256")"
echo "Size: $(du -h "${TARBALL}" | cut -f1)"
