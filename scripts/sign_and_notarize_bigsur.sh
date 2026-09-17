#!/bin/zsh
set -euo pipefail

APP="${APP:-DerivedData/Build/Products/Debug/Unsething.app}"
CERT="${CERT:?Set CERT to your Developer ID Application identity}"
APPLE_ID="${APPLE_ID:-}"
TEAM_ID="${TEAM_ID:-}"
ZIP="${ZIP:-DerivedData/Notarization/Unsething-bigsur-notarization.zip}"
ENTITLEMENTS="${ENTITLEMENTS:-Horos/Horos.entitlements}"

if [[ ! -d "$APP" ]]; then
  echo "App non trovata: $APP"
  echo "Esegui prima la build da Xcode oppure imposta APP=/percorso/Unsething.app"
  exit 1
fi

read -rs "APP_PASSWORD?Password specifica Apple: "
echo

echo "Rimuovo eventuali firme ad-hoc dai binari interni..."
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

echo "Firmo l'app principale..."
codesign --force --options runtime --timestamp \
  --entitlements "$ENTITLEMENTS" \
  --sign "$CERT" \
  "$APP"

echo "Verifico la firma..."
codesign --verify --deep --strict --verbose=4 "$APP"
codesign -dv --verbose=4 "$APP" 2>&1 | grep -E "Authority|TeamIdentifier|Timestamp|Runtime|Signature"

echo "Creo archivio per notarizzazione..."
mkdir -p "$(dirname "$ZIP")"
rm -f "$ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

echo "Invio ad Apple..."
xcrun notarytool submit "$ZIP" \
  --apple-id "$APPLE_ID" \
  --team-id "$TEAM_ID" \
  --password "$APP_PASSWORD" \
  --wait

echo "Aggancio il ticket di notarizzazione all'app..."
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"

echo "Controllo Gatekeeper..."
spctl --assess --type execute --verbose=4 "$APP"

echo "Fatto: $APP"
