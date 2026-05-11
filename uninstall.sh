#!/usr/bin/env bash
#
# Completely removes Mac Mouse Improver:
#   - quits the running app
#   - deletes the .app from /Applications and ~/Applications
#   - clears its preferences
#   - removes the login item if it was set
#
# Usage:
#   ./uninstall.sh

set -u

APP_NAME="Mac Mouse Improver"
BUNDLE_ID="dev.macmouseimprover.app"
BIN_NAME="MacMouseImprover"

echo "==> Quitting"
osascript -e "tell application \"$APP_NAME\" to quit" >/dev/null 2>&1 || true
killall "$BIN_NAME" >/dev/null 2>&1 || true
sleep 1
killall -9 "$BIN_NAME" >/dev/null 2>&1 || true

for path in "/Applications/${APP_NAME}.app" "$HOME/Applications/${APP_NAME}.app"; do
    if [[ -d "$path" ]]; then
        echo "==> Removing $path"
        rm -rf "$path"
    fi
done

echo "==> Removing preferences"
defaults delete "$BUNDLE_ID" >/dev/null 2>&1 || true

echo "==> Removing login item"
osascript -e "tell application \"System Events\" to delete login item \"$APP_NAME\"" >/dev/null 2>&1 || true
launchctl bootout "gui/$UID/application.${BUNDLE_ID}.${BUNDLE_ID}" >/dev/null 2>&1 || true

echo ""
echo "  Mac Mouse Improver has been uninstalled."
echo "  If the menu bar icon is still showing, log out and back in (or restart)."
