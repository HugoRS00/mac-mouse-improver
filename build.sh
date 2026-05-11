#!/usr/bin/env bash
#
# Build script for Mac Mouse Improver.
#
# Produces a signed-with-ad-hoc-signature .app bundle at:
#   build/Mac Mouse Improver.app
#
# Usage:
#   ./build.sh              # native architecture
#   ./build.sh --universal  # universal binary (arm64 + x86_64)

set -euo pipefail

APP_NAME="Mac Mouse Improver"
BIN_NAME="MacMouseImprover"
MIN_MACOS="12.0"

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT/build"
APP_BUNDLE="$BUILD_DIR/${APP_NAME}.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

UNIVERSAL=false
for arg in "$@"; do
    case "$arg" in
        --universal) UNIVERSAL=true ;;
        --help|-h)
            grep '^#' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
    esac
done

if [[ "$(uname)" != "Darwin" ]]; then
    echo "error: this script must be run on macOS"
    exit 1
fi

if ! command -v swiftc >/dev/null 2>&1; then
    echo "error: swiftc not found"
    echo "       install the Xcode Command Line Tools: xcode-select --install"
    exit 1
fi

echo "==> Cleaning $BUILD_DIR"
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

SOURCES=()
while IFS= read -r -d '' file; do
    SOURCES+=("$file")
done < <(find "$ROOT/Sources" -name '*.swift' -print0)

if [[ ${#SOURCES[@]} -eq 0 ]]; then
    echo "error: no Swift sources found in $ROOT/Sources"
    exit 1
fi

echo "==> Compiling Swift sources (${#SOURCES[@]} files)"

if $UNIVERSAL; then
    echo "    target: universal (arm64 + x86_64)"
    swiftc -O -target arm64-apple-macos$MIN_MACOS \
        -framework AppKit \
        -o "$BUILD_DIR/${BIN_NAME}-arm64" "${SOURCES[@]}"
    swiftc -O -target x86_64-apple-macos$MIN_MACOS \
        -framework AppKit \
        -o "$BUILD_DIR/${BIN_NAME}-x86_64" "${SOURCES[@]}"
    lipo -create \
        "$BUILD_DIR/${BIN_NAME}-arm64" \
        "$BUILD_DIR/${BIN_NAME}-x86_64" \
        -output "$MACOS_DIR/$BIN_NAME"
    rm -f "$BUILD_DIR/${BIN_NAME}-arm64" "$BUILD_DIR/${BIN_NAME}-x86_64"
else
    ARCH="$(uname -m)"
    echo "    target: $ARCH"
    swiftc -O -target "$ARCH-apple-macos$MIN_MACOS" \
        -framework AppKit \
        -o "$MACOS_DIR/$BIN_NAME" "${SOURCES[@]}"
fi

echo "==> Bundling"
cp "$ROOT/Info.plist" "$CONTENTS_DIR/Info.plist"

echo "==> Ad-hoc signing"
codesign --force --deep --sign - "$APP_BUNDLE"

echo ""
echo "  Built: $APP_BUNDLE"
echo ""
echo "  Run:     open \"$APP_BUNDLE\""
echo "  Install: cp -R \"$APP_BUNDLE\" /Applications/"
