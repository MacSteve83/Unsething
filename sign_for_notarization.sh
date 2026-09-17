#!/bin/bash
set -euo pipefail

IDENTITY="${IDENTITY:?Set IDENTITY to your Developer ID Application identity}"
APP="DerivedData/Build/Products/Debug/Unsething.app"
ENTITLEMENTS="Horos/Horos.entitlements"
ZIP="DerivedData/Notarization/Unsething-notarization.zip"

if [ ! -d "$APP" ]; then
  echo "App non trovata: $APP"
  exit 1
fi

echo "Firmo gli eseguibili interni..."
for item in \
  "$APP/Contents/Resources/dsr2html" \
  "$APP/Contents/Resources/Decompress" \
  "$APP/Contents/Resources/dcmpsprt" \
  "$APP/Contents/Resources/dcmdump" \
  "$APP/Contents/Resources/dcmprscu" \
  "$APP/Contents/Resources/echoscu"
do
  if [ -e "$item" ]; then
    codesign --force --options runtime --timestamp --sign "$IDENTITY" "$item"
  fi
done

echo "Rifirmo framework..."
for fw in "$APP/Contents/Frameworks/"*.framework; do
  [ -e "$fw" ] && codesign --force --deep --options runtime --timestamp --sign "$IDENTITY" "$fw"
done

echo "Rifirmo Unsething.app..."
codesign --force --options runtime --timestamp --entitlements "$ENTITLEMENTS" --sign "$IDENTITY" "$APP"

echo "Verifico la firma..."
codesign --verify --deep --strict --verbose=4 "$APP"

echo "Ricreo lo zip per Apple..."
mkdir -p "$(dirname "$ZIP")"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "Pronto: $ZIP"
