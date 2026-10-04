#!/usr/bin/env bash
set -euo pipefail

required=(TANKTIME_ADMOB_APP_ID TANKTIME_ADMOB_BANNER_ID TANKTIME_ADMOB_INTERSTITIAL_ID)
for key in "${required[@]}"; do
  value="${!key:-}"
  if [[ -z "$value" ]]; then
    echo "ERROR: missing release secret $key" >&2
    exit 20
  fi
  if [[ "$value" == *"3940256099942544"* ]]; then
    echo "ERROR: Google test ID found in $key" >&2
    exit 21
  fi
done

[[ "$TANKTIME_ADMOB_APP_ID" =~ ^ca-app-pub-[0-9]+~[0-9]+$ ]] || { echo "ERROR: invalid AdMob App ID" >&2; exit 22; }
[[ "$TANKTIME_ADMOB_BANNER_ID" =~ ^ca-app-pub-[0-9]+/[0-9]+$ ]] || { echo "ERROR: invalid banner ID" >&2; exit 23; }
[[ "$TANKTIME_ADMOB_INTERSTITIAL_ID" =~ ^ca-app-pub-[0-9]+/[0-9]+$ ]] || { echo "ERROR: invalid interstitial ID" >&2; exit 24; }

echo "PASS: production AdMob IDs are present and are not Google test IDs."

INHERITED_ICON_SHA='59D21284BBD7CB67ED017022D62A742BBB74A01D9DE0EC67F99C2BAAABAA69D7'
ICON_PATH='TankTime/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png'
[[ -f "$ICON_PATH" ]] || { echo "ERROR: missing TankTime AppIcon-1024.png" >&2; exit 25; }
CURRENT_ICON_SHA=$(shasum -a 256 "$ICON_PATH" | awk '{print toupper($1)}')
[[ "$CURRENT_ICON_SHA" != "$INHERITED_ICON_SHA" ]] || { echo "ERROR: inherited TrimBench icon is still installed" >&2; exit 26; }

echo "PASS: TankTime icon differs from inherited TrimBench placeholder."
