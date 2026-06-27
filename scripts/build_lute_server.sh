#!/usr/bin/env bash
# Build a standalone lute-v3 server artifact for Android arm64.
#
# Produces:
#   dist/lute-server-android-arm64-v<version>.tar.gz
#   dist/lute-server-android-arm64-v<version>.tar.gz.sha256
#
# Requirements on the build host:
#   - Python 3.10+ (matching the lute-v3 minimum)
#   - Docker (recommended) OR a Linux aarch64 build environment
#   - ~3 GB free disk
#
# Usage:
#   scripts/build_lute_server.sh [LUTE_VERSION]
#   scripts/build_lute_server.sh 3.10.1

set -euo pipefail

LUTE_VERSION="${1:-3.10.1}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build/lute-server"
DIST_DIR="${ROOT_DIR}/dist"
TARBALL_NAME="lute-server-android-arm64-v${LUTE_VERSION}.tar.gz"
TARBALL="${DIST_DIR}/${TARBALL_NAME}"

echo "==> Cloning LuteOrg/lute-v3 at tag ${LUTE_VERSION}"
rm -rf "${BUILD_DIR}"
git clone --depth 1 --branch "${LUTE_VERSION}" \
  https://github.com/LuteOrg/lute-v3.git "${BUILD_DIR}"

echo "==> Building arm64 artifact"
mkdir -p "${DIST_DIR}"

# Strategy: build a standalone Python environment that we can tar up.
# The recipient (Android app) extracts the tarball and runs
# <extract-dir>/python -m lute.main --port N --datapath ...
#
# We use the 'manylinux' aarch64 build of CPython as the interpreter.
# This is the standard way to ship Python-on-Android without Chaquopy.
#
# If you don't have Docker, replace the docker run with a manual build
# (see the "manual" branch below).

PYTHON_VERSION="3.11"
PYTHON_IMAGE="quay.io/pypa/manylinux2014_aarch64"

if command -v docker >/dev/null 2>&1; then
  echo "==> Building inside ${PYTHON_IMAGE}"
  docker run --rm -v "${BUILD_DIR}:/src" -v "${DIST_DIR}:/out" \
    "${PYTHON_IMAGE}" bash -s <<'BASH'
set -euo pipefail
PY_VERSION="3.11"
SRC=/src
DEST=/out/build
rm -rf "${DEST}"
mkdir -p "${DEST}/python" "${DEST}/lute"

# Install a relocatable Python.
PY_PREFIX="/opt/_internal/cpython-${PY_VERSION}.*/bin"
# manylinux images have multiple Python versions under /opt/_internal.
PY_BIN_DIR=$(ls -d /opt/_internal/cpython-${PY_VERSION}.* 2>/dev/null | head -1 || true)
if [ -z "${PY_BIN_DIR}" ]; then
  echo "ERROR: Python ${PY_VERSION} not found in manylinux image."
  echo "Available versions:"
  ls /opt/_internal/ 2>/dev/null || true
  exit 1
fi
echo "Using Python from ${PY_BIN_DIR}"

# Copy the Python install into our artifact, stripped down.
cp -a "${PY_BIN_DIR}/." "${DEST}/python/"
# Drop test packages we don't need.
rm -rf "${DEST}/python/lib/python${PY_VERSION}/test"
rm -rf "${DEST}/python/lib/python${PY_VERSION}/__pycache__"

# Install pip into this Python.
"${DEST}/python/bin/python${PY_VERSION}" -m ensurepip --upgrade

# Install lute's runtime deps into lute-deps/, skipping natto-py (the
# MeCab C extension, which can't build for aarch64-linux-android and
# isn't bundled in v1).
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
  "${DEPS[@]}"

# Copy the lute package itself on top of lute-deps/ so it sits at
# lute-deps/lute/. The launcher uses PYTHONPATH=<dest>/lute-deps.
cp -a "${SRC}/lute/." "${DEST}/lute-deps/lute/"

# Make a tiny launcher that adds lute-deps to PYTHONPATH and invokes lute.
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

echo "==> Built lute-server at ${DEST}"
BASH

  # Copy out the build dir from the container.
  SRC_OUT="${DIST_DIR}/build"
  echo "==> Collecting artifact from ${SRC_OUT}"
  tar -czf "${TARBALL}" -C "${SRC_OUT}" .
  rm -rf "${SRC_OUT}"
else
  echo "ERROR: Docker is required for cross-compiling Python for aarch64."
  echo "Install Docker, or extend this script to use a native aarch64 host."
  exit 1
fi

echo "==> Computing SHA256"
sha256sum "${TARBALL}" | awk '{print $1}' > "${TARBALL}.sha256"

echo ""
echo "Built: ${TARBALL}"
echo "SHA256: $(cat "${TARBALL}.sha256")"
echo "Size: $(du -h "${TARBALL}" | cut -f1)"
