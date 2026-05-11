#!/usr/bin/env bash
#
# Builds Mac Mouse Improver and installs it to /Applications, then launches it.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Mac Mouse Improver"
APP_BUNDLE="$ROOT/build/${APP_NAME}.app"
DEST="/Applications/${APP_NAME}.app"

"$ROOT/build.sh" "$@"

if [[ -d "$DEST" ]]; then
    echo "==> Replacing existing $DEST"
    rm -rf "$DEST"
fi

echo "==> Copying to /Applications"
cp -R "$APP_BUNDLE" "$DEST"

# Remove quarantine flag so it can run without right-click → Open dance.
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

echo "==> Launching"
open "$DEST"

echo ""
echo "  Installed: $DEST"
echo "  Look for the cursor icon in your menu bar."
