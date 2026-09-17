#!/bin/zsh
set -euo pipefail

APP="${APP:-DerivedData/Build/Products/Debug/Unsething.app}"
APP_NAME="${APP_NAME:-$(basename "$APP")}"
VERSION="${VERSION:-}"
VOLUME_NAME="${VOLUME_NAME:-}"
DMG="${DMG:-}"
WORK_DIR="${WORK_DIR:-DerivedData/DMG}"
STAGING_DIR="$WORK_DIR/staging"
BACKGROUND_DIR="$STAGING_DIR/.background"
BACKGROUND_IMAGE="$BACKGROUND_DIR/background.png"

if [[ ! -d "$APP" ]]; then
  echo "App non trovata: $APP"
  echo "Esegui prima la build oppure imposta APP=/percorso/Unsething.app"
  exit 1
fi

if [[ -z "$VERSION" ]]; then
  VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist" 2>/dev/null || echo "1.2.0")
fi

VOLUME_NAME="${VOLUME_NAME:-Unsething ${VERSION}}"
DMG="${DMG:-DerivedData/Notarization/Unsething-${VERSION}.dmg}"
RW_DMG="$WORK_DIR/Unsething-${VERSION}-rw.dmg"

rm -rf "$WORK_DIR"
mkdir -p "$BACKGROUND_DIR" "$(dirname "$DMG")"

echo "Preparo il contenuto del DMG..."
ditto "$APP" "$STAGING_DIR/$APP_NAME"
ln -s /Applications "$STAGING_DIR/Applicazioni"

echo "Creo lo sfondo con istruzione di copia..."
BACKGROUND_IMAGE="$BACKGROUND_IMAGE" APP_NAME="$APP_NAME" python3 - <<'PY'
import os
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

out = Path(os.environ["BACKGROUND_IMAGE"])
width, height = 660, 420
img = Image.new("RGB", (width, height), "#f7fbff")
draw = ImageDraw.Draw(img)

primary = "#79a9d9"
secondary = "#23445f"
muted = "#7f9cb4"

def font(size, bold=False):
    candidates = [
        "/System/Library/Fonts/Supplemental/Avenir Next.ttc",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size=size)
        except Exception:
            pass
    return ImageFont.load_default()

title_font = font(30, True)
small_font = font(15, False)

draw.rounded_rectangle((22, 22, width - 22, height - 22), radius=26, outline="#d8e7f4", width=2)

text = "Copia in Applicazioni"
bbox = draw.textbbox((0, 0), text, font=title_font)
draw.text(((width - (bbox[2] - bbox[0])) / 2, 72), text, font=title_font, fill=secondary)

app_label = os.environ["APP_NAME"].removesuffix(".app")
subtitle = f"Trascina {app_label} nella cartella Applicazioni"
bbox = draw.textbbox((0, 0), subtitle, font=small_font)
draw.text(((width - (bbox[2] - bbox[0])) / 2, 114), subtitle, font=small_font, fill=muted)

# Arrow between app and Applications icons.
y = 235
draw.line((248, y, 412, y), fill=primary, width=8)
draw.polygon([(412, y), (384, y - 18), (384, y + 18)], fill=primary)
draw.line((248, y, 412, y), fill="#5f95c8", width=3)

draw.text((115, 306), app_label, font=small_font, fill=secondary)
draw.text((445, 306), "Applicazioni", font=small_font, fill=secondary)

img.save(out)
PY

APP_MB=$(du -sm "$STAGING_DIR" | awk '{print $1}')
DMG_SIZE="$((APP_MB + 120))m"

echo "Creo immagine disco temporanea..."
hdiutil create -volname "$VOLUME_NAME" -srcfolder "$STAGING_DIR" -ov -format UDRW -size "$DMG_SIZE" "$RW_DMG" >/dev/null

echo "Imposto layout Finder..."
MOUNT_INFO=$(hdiutil attach "$RW_DMG" -readwrite -noverify -noautoopen)
MOUNT_POINT=$(printf '%s\n' "$MOUNT_INFO" | sed -n 's#^.*\(/Volumes/.*\)$#\1#p' | head -n 1)

if [[ -z "${MOUNT_POINT:-}" || ! -d "$MOUNT_POINT" ]]; then
  echo "Impossibile montare il DMG temporaneo"
  exit 1
fi

chflags hidden "$MOUNT_POINT/.background" 2>/dev/null || true

osascript <<OSA
tell application "Finder"
  tell disk "$VOLUME_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {120, 120, 780, 540}
    set theViewOptions to icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to 96
    set background picture of theViewOptions to file ".background:background.png"
    set position of item "$APP_NAME" of container window to {170, 235}
    set position of item "Applicazioni" of container window to {490, 235}
    update without registering applications
    delay 1
    close
  end tell
end tell
OSA

sync
hdiutil detach "$MOUNT_POINT" >/dev/null

echo "Comprimo il DMG finale..."
rm -f "$DMG"
hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG" >/dev/null
hdiutil verify "$DMG" >/dev/null

echo "DMG pronto: $DMG"
