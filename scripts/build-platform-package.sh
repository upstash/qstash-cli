#!/usr/bin/env bash
# Assembles a publishable npm subpackage for one platform/arch by downloading
# the matching qstash-server release from artifacts.upstash.com.
#
# Usage:
#   scripts/build-platform-package.sh <VERSION> <NODE_PLATFORM> <NODE_ARCH> <OUT_DIR>
#
# NODE_PLATFORM is the Node.js process.platform value: darwin | linux | win32
# NODE_ARCH is the Node.js process.arch value: arm64 | x64
#
# On success, OUT_DIR contains a directory ready for `npm publish`.

set -euo pipefail

VERSION="${1:?VERSION required}"
NODE_PLATFORM="${2:?NODE_PLATFORM required (darwin|linux|win32)}"
NODE_ARCH="${3:?NODE_ARCH required (arm64|x64)}"
OUT_DIR="${4:?OUT_DIR required}"

case "$NODE_PLATFORM" in
  darwin)  ARTIFACT_PLATFORM="darwin"; EXT="tar.gz"; BIN_NAME="qstash" ;;
  linux)   ARTIFACT_PLATFORM="linux";  EXT="tar.gz"; BIN_NAME="qstash" ;;
  win32)   ARTIFACT_PLATFORM="windows"; EXT="zip";   BIN_NAME="qstash.exe" ;;
  *) echo "Unsupported NODE_PLATFORM: $NODE_PLATFORM" >&2; exit 1 ;;
esac

case "$NODE_ARCH" in
  arm64) ARTIFACT_ARCH="arm64" ;;
  x64)   ARTIFACT_ARCH="amd64" ;;
  *) echo "Unsupported NODE_ARCH: $NODE_ARCH" >&2; exit 1 ;;
esac

PKG_NAME="@upstash/qstash-cli-${NODE_PLATFORM}-${NODE_ARCH}"
ARCHIVE="qstash-server_${VERSION}_${ARTIFACT_PLATFORM}_${ARTIFACT_ARCH}.${EXT}"
URL="https://artifacts.upstash.com/qstash/versions/${VERSION}/${ARCHIVE}"

echo "Building ${PKG_NAME}@${VERSION} from ${URL}"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR/bin"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl --fail --silent --show-error --location --output "${TMP}/${ARCHIVE}" "$URL"

case "$EXT" in
  tar.gz) tar -xzf "${TMP}/${ARCHIVE}" -C "$TMP" ;;
  zip)    unzip -q "${TMP}/${ARCHIVE}" -d "$TMP" ;;
esac

if [ ! -f "${TMP}/${BIN_NAME}" ]; then
  echo "Expected ${BIN_NAME} in ${ARCHIVE} but it was not found." >&2
  ls -la "$TMP" >&2
  exit 1
fi

cp "${TMP}/${BIN_NAME}" "${OUT_DIR}/bin/${BIN_NAME}"
chmod +x "${OUT_DIR}/bin/${BIN_NAME}"

if [ -f "${TMP}/LICENSE.txt" ]; then
  cp "${TMP}/LICENSE.txt" "${OUT_DIR}/LICENSE.txt"
fi

cat > "${OUT_DIR}/package.json" <<EOF
{
  "name": "${PKG_NAME}",
  "version": "${VERSION}",
  "description": "QStash CLI binary for ${NODE_PLATFORM}/${NODE_ARCH}. Installed automatically by @upstash/qstash-cli.",
  "license": "ISC",
  "repository": {
    "type": "git",
    "url": "git+https://github.com/upstash/qstash-cli.git"
  },
  "os": ["${NODE_PLATFORM}"],
  "cpu": ["${NODE_ARCH}"],
  "files": ["bin", "LICENSE.txt"]
}
EOF

cat > "${OUT_DIR}/README.md" <<EOF
# ${PKG_NAME}

Platform-specific binary for [\`@upstash/qstash-cli\`](https://www.npmjs.com/package/@upstash/qstash-cli).

Do not install this package directly. Install \`@upstash/qstash-cli\` and the
correct binary package will be selected automatically based on your operating
system and architecture.
EOF

echo "Built ${PKG_NAME}@${VERSION} -> ${OUT_DIR}"
ls -la "${OUT_DIR}" "${OUT_DIR}/bin"
