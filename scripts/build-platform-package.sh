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
#
# Security:
#   - Verifies the downloaded archive against the SHA-256 checksum manifest
#     published alongside the release at artifacts.upstash.com.
#   - Sanity-checks the extracted binary's file-type against the platform/arch
#     slot it is being packaged into.
#   - Extracts into a fresh mktemp directory with restrictive tar flags.

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
MANIFEST="qstash-server_${VERSION}_checksums.txt"
BASE_URL="https://artifacts.upstash.com/qstash/versions/${VERSION}"

echo "Building ${PKG_NAME}@${VERSION} from ${BASE_URL}/${ARCHIVE}"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR/bin"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# 1. Download the archive and the upstream SHA-256 manifest.
curl --fail --silent --show-error --location --output "${TMP}/${ARCHIVE}"  "${BASE_URL}/${ARCHIVE}"
curl --fail --silent --show-error --location --output "${TMP}/${MANIFEST}" "${BASE_URL}/${MANIFEST}"

# 2. Verify the archive against the manifest.
#    Filter the manifest down to exactly the line for our archive so a missing
#    or malformed line is caught (sha256sum --ignore-missing alone would silently
#    pass if our line weren't present at all).
if command -v sha256sum >/dev/null 2>&1; then
  SHASUM_CMD=(sha256sum -c)
else
  SHASUM_CMD=(shasum -a 256 -c)
fi
grep -F "  ${ARCHIVE}" "${TMP}/${MANIFEST}" > "${TMP}/expected.sha256" \
  || { echo "Archive ${ARCHIVE} is not listed in ${MANIFEST}" >&2; exit 1; }
(cd "$TMP" && "${SHASUM_CMD[@]}" expected.sha256) \
  || { echo "Checksum verification failed for ${ARCHIVE}" >&2; exit 1; }

# 3. Extract with restrictive flags. tar already refuses absolute / "../" paths
#    by default; --no-same-owner / --no-same-permissions strip metadata that
#    could otherwise be carried across.
case "$EXT" in
  tar.gz) tar --no-same-owner --no-same-permissions -xzf "${TMP}/${ARCHIVE}" -C "$TMP" ;;
  zip)    unzip -q "${TMP}/${ARCHIVE}" -d "$TMP" ;;
esac

if [ ! -f "${TMP}/${BIN_NAME}" ]; then
  echo "Expected ${BIN_NAME} in ${ARCHIVE} but it was not found." >&2
  ls -la "$TMP" >&2
  exit 1
fi

# 4. Sanity-check the binary's file-type matches the slot we're packaging it
#    into. Defends against the upstream accidentally publishing the wrong
#    binary into the wrong filename (checksum verify alone does not catch this).
case "${NODE_PLATFORM}-${NODE_ARCH}" in
  darwin-arm64) EXPECT_FAMILY="Mach-O" EXPECT_ARCH="arm64"   ;;
  darwin-x64)   EXPECT_FAMILY="Mach-O" EXPECT_ARCH="x86_64"  ;;
  linux-arm64)  EXPECT_FAMILY="ELF"    EXPECT_ARCH="aarch64" ;;
  linux-x64)    EXPECT_FAMILY="ELF"    EXPECT_ARCH="x86-64"  ;;
  win32-arm64)  EXPECT_FAMILY="PE32"   EXPECT_ARCH="Aarch64" ;;
  win32-x64)    EXPECT_FAMILY="PE32"   EXPECT_ARCH="x86-64"  ;;
esac
FILE_OUT="$(file --brief "${TMP}/${BIN_NAME}")"
if [[ "$FILE_OUT" != *"$EXPECT_FAMILY"* || "$FILE_OUT" != *"$EXPECT_ARCH"* ]]; then
  echo "File-type sanity check failed for ${BIN_NAME}." >&2
  echo "  expected: ${EXPECT_FAMILY} ... ${EXPECT_ARCH}" >&2
  echo "  got:      ${FILE_OUT}" >&2
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
