#!/bin/zsh
set -euo pipefail

APP="${APP:-DerivedData/Build/Products/Debug/Unsething.app}"
CERT="${CERT:?Set CERT to your Developer ID Application identity}"
APPLE_ID="${APPLE_ID:-}"
TEAM_ID="${TEAM_ID:-}"
ENTITLEMENTS="${ENTITLEMENTS:-Horos/Horos.entitlements}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"

if [[ ! -d "$APP" ]]; then
  echo "App non trovata: $APP"
  echo "Esegui prima la build da Xcode oppure imposta APP=/percorso/Unsething.app"
  exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist" 2>/dev/null || echo "1.2.0")
DMG="${DMG:-DerivedData/Notarization/Unsething-${VERSION}.dmg}"

echo "Versione app: $VERSION"
echo "Certificato: $CERT"

echo "Rimuovo eventuali firme vecchie dai binari interni..."
find "$APP/Contents" -type f -perm -111 -print0 | while IFS= read -r -d '' file; do
  if file "$file" | grep -q "Mach-O"; then
    codesign --remove-signature "$file" 2>/dev/null || true
  fi
done

echo "Firmo helper e binari interni..."
find "$APP/Contents" -type f -perm -111 -print0 | while IFS= read -r -d '' file; do
  if file "$file" | grep -q "Mach-O"; then
    case "$file" in
      "$APP/Contents/MacOS/"*)
        continue
        ;;
    esac
    codesign --force --options runtime --timestamp --sign "$CERT" "$file"
  fi
done

echo "Firmo plugin e framework..."
for bundle_dir in "$APP/Contents/PlugIns" "$APP/Contents/Frameworks"; do
  [[ -d "$bundle_dir" ]] || continue
  find "$bundle_dir" -maxdepth 1 -mindepth 1 -print0 | while IFS= read -r -d '' bundle; do
    codesign --force --options runtime --timestamp --sign "$CERT" "$bundle"
  done
done

echo "Firmo Unsething.app..."
codesign --force --options runtime --timestamp \
  --entitlements "$ENTITLEMENTS" \
  --sign "$CERT" \
  "$APP"

echo "Verifico firma app..."
codesign --verify --deep --strict --verbose=4 "$APP"
codesign -dv --verbose=4 "$APP" 2>&1 | grep -E "Authority|TeamIdentifier|Timestamp|Runtime|Signature"

echo "Creo DMG di distribuzione..."
DMG="$DMG" APP="$APP" VERSION="$VERSION" ./scripts/create_distribution_dmg.sh

echo "Firmo DMG..."
codesign --force --timestamp --sign "$CERT" "$DMG"
codesign --verify --verbose=4 "$DMG"

echo "Invio DMG ad Apple per notarizzazione..."
if [[ -n "$NOTARY_PROFILE" ]]; then
  xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
else
  read -rs "APP_PASSWORD?Password specifica Apple: "
  echo
  xcrun notarytool submit "$DMG" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_PASSWORD" \
    --wait
fi

echo "Aggancio ticket di notarizzazione..."
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"

echo "Controllo Gatekeeper..."
spctl --assess --type execute --verbose=4 "$APP"
spctl --assess --type open --context context:primary-signature --verbose=4 "$DMG"

echo "Fatto: $DMG"
