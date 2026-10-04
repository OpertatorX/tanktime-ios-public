#!/usr/bin/env bash
set -euo pipefail

SOURCE="artwork/TankTime-AppIconSource.jpg"
OUTPUT="TankTime/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

[[ -f "$SOURCE" ]] || { echo "ERROR: missing $SOURCE" >&2; exit 30; }

if command -v magick >/dev/null 2>&1; then
  MAGICK=(magick)
elif command -v convert >/dev/null 2>&1; then
  MAGICK=(convert)
else
  echo "ERROR: ImageMagick is required to materialize the TankTime icon" >&2
  exit 31
fi

mkdir -p "$(dirname "$OUTPUT")"
"${MAGICK[@]}" "$SOURCE" \
  -auto-orient \
  -resize 1024x1024^ \
  -gravity center \
  -extent 1024x1024 \
  -alpha off \
  -colorspace sRGB \
  -strip "$OUTPUT"

DIMS=$("${MAGICK[@]}" identify -format '%wx%h' "$OUTPUT" 2>/dev/null || identify -format '%wx%h' "$OUTPUT")
[[ "$DIMS" == "1024x1024" ]] || { echo "ERROR: app icon dimensions are $DIMS" >&2; exit 32; }

CHANNELS=$("${MAGICK[@]}" identify -format '%[channels]' "$OUTPUT" 2>/dev/null || identify -format '%[channels]' "$OUTPUT")
if [[ "$CHANNELS" == *a* ]]; then
  echo "ERROR: app icon still contains an alpha channel ($CHANNELS)" >&2
  exit 33
fi

echo "PASS: premium TankTime app icon materialized at $OUTPUT ($DIMS, $CHANNELS)."
