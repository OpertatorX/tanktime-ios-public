#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import os
import sys
import time
from pathlib import Path
from urllib.parse import quote

import jwt
import requests

API = "https://api.appstoreconnect.apple.com"
APP_ID = os.environ.get("ASC_APP_ID", "6818814141")
VERSION = os.environ.get("ASC_VERSION", "1.0")
KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
KEY_B64 = os.environ["ASC_API_KEY_BASE64"]
ROOT = Path(__file__).resolve().parents[1]
SCREEN_ROOT = ROOT / "screenshots-promo"
DISPLAY_TYPES = {
    "iphone": "APP_IPHONE_67",
    "ipad": "APP_IPAD_PRO_3GEN_129",
}


def bearer() -> str:
    import base64
    private_key = base64.b64decode(KEY_B64).decode("utf-8")
    now = int(time.time())
    token = jwt.encode(
        {"iss": ISSUER_ID, "iat": now, "exp": now + 15 * 60, "aud": "appstoreconnect-v1"},
        private_key,
        algorithm="ES256",
        headers={"kid": KEY_ID, "typ": "JWT"},
    )
    return token


TOKEN = bearer()


def api(method: str, path: str, *, params=None, json=None, expected=(200, 201, 204)):
    response = requests.request(
        method,
        API + path,
        params=params,
        json=json,
        headers={"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"},
        timeout=60,
    )
    if response.status_code not in expected:
        raise RuntimeError(f"{method} {path} -> {response.status_code}: {response.text[:1200]}")
    if response.status_code == 204:
        return None
    return response.json()


def version_id() -> str:
    payload = api(
        "GET",
        f"/v1/apps/{APP_ID}/appStoreVersions",
        params={"filter[platform]": "IOS", "filter[versionString]": VERSION, "limit": 10},
    )
    matches = payload.get("data", [])
    if not matches:
        raise RuntimeError(f"No iOS App Store version {VERSION} found for app {APP_ID}")
    return matches[0]["id"]


def localizations(store_version_id: str) -> dict[str, str]:
    payload = api(
        "GET",
        f"/v1/appStoreVersions/{store_version_id}/appStoreVersionLocalizations",
        params={"limit": 200},
    )
    return {item["attributes"]["locale"]: item["id"] for item in payload.get("data", [])}


def replace_set(localization_id: str, display_type: str) -> str:
    existing = api(
        "GET",
        f"/v1/appStoreVersionLocalizations/{localization_id}/appScreenshotSets",
        params={"filter[screenshotDisplayType]": display_type, "limit": 50},
    )
    for item in existing.get("data", []):
        api("DELETE", f"/v1/appScreenshotSets/{item['id']}", expected=(204,))
    created = api(
        "POST",
        "/v1/appScreenshotSets",
        json={
            "data": {
                "type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": display_type},
                "relationships": {
                    "appStoreVersionLocalization": {
                        "data": {"type": "appStoreVersionLocalizations", "id": localization_id}
                    }
                },
            }
        },
    )
    return created["data"]["id"]


def upload_one(set_id: str, path: Path) -> str:
    data = path.read_bytes()
    reservation = api(
        "POST",
        "/v1/appScreenshots",
        json={
            "data": {
                "type": "appScreenshots",
                "attributes": {"fileName": path.name, "fileSize": len(data)},
                "relationships": {
                    "appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}
                },
            }
        },
    )["data"]
    screenshot_id = reservation["id"]
    for operation in reservation["attributes"].get("uploadOperations", []):
        offset = operation["offset"]
        length = operation["length"]
        headers = {h["name"]: h["value"] for h in operation.get("requestHeaders", [])}
        response = requests.request(
            operation["method"],
            operation["url"],
            data=data[offset : offset + length],
            headers=headers,
            timeout=120,
        )
        if not 200 <= response.status_code < 300:
            raise RuntimeError(f"asset PUT failed {response.status_code}: {response.text[:500]}")
    checksum = hashlib.md5(data).hexdigest()
    api(
        "PATCH",
        f"/v1/appScreenshots/{screenshot_id}",
        json={
            "data": {
                "type": "appScreenshots",
                "id": screenshot_id,
                "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
            }
        },
    )
    return screenshot_id


def wait_complete(screenshot_id: str) -> None:
    deadline = time.time() + 180
    while time.time() < deadline:
        item = api("GET", f"/v1/appScreenshots/{screenshot_id}")["data"]
        state = item["attributes"].get("assetDeliveryState", {}).get("state", "")
        if state in {"COMPLETE", "UPLOAD_COMPLETE"}:
            return
        if state in {"FAILED", "ERROR"}:
            raise RuntimeError(f"Screenshot {screenshot_id} failed processing: {item['attributes'].get('assetDeliveryState')}")
        time.sleep(3)
    raise TimeoutError(f"Timed out waiting for screenshot {screenshot_id}")


def main() -> int:
    if not SCREEN_ROOT.exists():
        raise RuntimeError(f"Missing {SCREEN_ROOT}")
    store_version_id = version_id()
    locs = localizations(store_version_id)
    for locale in ("en-US", "fr-FR"):
        localization_id = locs.get(locale)
        if not localization_id:
            raise RuntimeError(f"Missing App Store localization {locale}")
        for device, display_type in DISPLAY_TYPES.items():
            folder = SCREEN_ROOT / locale / device
            files = sorted(folder.glob("*.png"))
            if not 1 <= len(files) <= 10:
                raise RuntimeError(f"Expected 1-10 screenshots in {folder}, found {len(files)}")
            set_id = replace_set(localization_id, display_type)
            print(f"Uploading {locale}/{device}: {len(files)} screenshots -> {display_type}")
            ids = []
            for path in files:
                screenshot_id = upload_one(set_id, path)
                ids.append(screenshot_id)
                wait_complete(screenshot_id)
                print(f"  OK {path.name}")
            api(
                "PATCH",
                f"/v1/appScreenshotSets/{set_id}/relationships/appScreenshots",
                json={"data": [{"type": "appScreenshots", "id": sid} for sid in ids]},
            )
    print("PASS: localized iPhone and iPad App Store screenshots uploaded.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise
