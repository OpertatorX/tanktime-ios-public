#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path

import requests

API = "https://admob.googleapis.com/v1beta"
PUBLISHER_ID = os.environ.get("ADMOB_PUBLISHER_ID", "pub-9441192520255287")
ACCOUNT = f"accounts/{PUBLISHER_ID}"
DISPLAY_NAME = os.environ.get("ADMOB_APP_DISPLAY_NAME", "TankTime")
QUOTA_PROJECT = os.environ.get("GOOGLE_CLOUD_QUOTA_PROJECT", "").strip()
OUT = Path(os.environ.get("ADMOB_OUTPUT_PATH", ".factory-private/tanktime-admob.json"))


def access_token() -> str:
    direct = os.environ.get("ADMOB_ACCESS_TOKEN", "").strip()
    if direct:
        return direct

    client_id = os.environ.get("GOOGLE_OAUTH_CLIENT_ID", "").strip()
    client_secret = os.environ.get("GOOGLE_OAUTH_CLIENT_SECRET", "").strip()
    refresh_token = os.environ.get("GOOGLE_OAUTH_REFRESH_TOKEN", "").strip()
    if not all((client_id, client_secret, refresh_token)):
        raise RuntimeError(
            "AdMob OAuth is missing. Set ADMOB_ACCESS_TOKEN or GOOGLE_OAUTH_CLIENT_ID, "
            "GOOGLE_OAUTH_CLIENT_SECRET and GOOGLE_OAUTH_REFRESH_TOKEN with the "
            "https://www.googleapis.com/auth/admob.monetization scope."
        )

    response = requests.post(
        "https://oauth2.googleapis.com/token",
        data={
            "client_id": client_id,
            "client_secret": client_secret,
            "refresh_token": refresh_token,
            "grant_type": "refresh_token",
        },
        timeout=30,
    )
    if response.status_code != 200:
        raise RuntimeError(f"Google OAuth refresh failed: {response.status_code} {response.text[:800]}")
    return response.json()["access_token"]


TOKEN = access_token()


def api(method: str, path: str, *, params=None, json_body=None, expected=(200, 201)):
    response = requests.request(
        method,
        f"{API}{path}",
        params=params,
        json=json_body,
        headers={**{"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"}, **({"x-goog-user-project": QUOTA_PROJECT} if QUOTA_PROJECT else {})},
        timeout=60,
    )
    if response.status_code not in expected:
        if response.status_code == 403:
            raise RuntimeError(
                "AdMob API returned 403. The v1beta create methods are limited-access; "
                "this account may require Google to enable AdMob inventory creation API access. "
                f"Response: {response.text[:1000]}"
            )
        raise RuntimeError(f"{method} {path} -> {response.status_code}: {response.text[:1200]}")
    return response.json()


def paged(path: str, key: str) -> list[dict]:
    items: list[dict] = []
    token = ""
    while True:
        params = {"pageSize": 1000}
        if token:
            params["pageToken"] = token
        payload = api("GET", path, params=params)
        items.extend(payload.get(key, []))
        token = payload.get("nextPageToken", "")
        if not token:
            return items


def find_app(apps: list[dict]) -> dict | None:
    candidates = []
    for app in apps:
        if app.get("platform") != "IOS":
            continue
        manual_name = app.get("manualAppInfo", {}).get("displayName", "")
        linked_name = app.get("linkedAppInfo", {}).get("displayName", "")
        if manual_name.casefold() == DISPLAY_NAME.casefold() or linked_name.casefold() == DISPLAY_NAME.casefold():
            candidates.append(app)
    if len(candidates) > 1:
        ids = [a.get("appId") for a in candidates]
        raise RuntimeError(f"Multiple iOS AdMob apps named {DISPLAY_NAME!r} exist: {ids}")
    return candidates[0] if candidates else None


def ensure_app() -> dict:
    apps = paged(f"/{ACCOUNT}/apps", "apps")
    existing = find_app(apps)
    if existing:
        print(f"Reusing AdMob app {existing.get('appId')}")
        return existing
    print(f"Creating manual iOS AdMob app {DISPLAY_NAME!r}...")
    return api(
        "POST",
        f"/{ACCOUNT}/apps",
        json_body={"platform": "IOS", "manualAppInfo": {"displayName": DISPLAY_NAME}},
    )


def ensure_ad_unit(app_id: str, display_name: str, ad_format: str) -> dict:
    units = paged(f"/{ACCOUNT}/adUnits", "adUnits")
    matches = [
        u for u in units
        if u.get("appId") == app_id
        and u.get("displayName", "").casefold() == display_name.casefold()
        and u.get("adFormat") == ad_format
    ]
    if len(matches) > 1:
        raise RuntimeError(f"Multiple {ad_format} units named {display_name!r} exist for {app_id}")
    if matches:
        print(f"Reusing {ad_format} unit {matches[0].get('adUnitId')}")
        return matches[0]

    ad_types = ["RICH_MEDIA", "VIDEO"]
    print(f"Creating {ad_format} unit {display_name!r}...")
    return api(
        "POST",
        f"/{ACCOUNT}/adUnits",
        json_body={
            "appId": app_id,
            "displayName": display_name,
            "adFormat": ad_format,
            "adTypes": ad_types,
        },
    )


def validate_id(value: str, separator: str) -> None:
    prefix = f"ca-app-pub-{PUBLISHER_ID.removeprefix('pub-')}{separator}"
    if not value.startswith(prefix):
        raise RuntimeError(f"Unexpected AdMob ID {value!r}; expected publisher {PUBLISHER_ID}")


def main() -> int:
    app = ensure_app()
    app_id = app["appId"]
    validate_id(app_id, "~")

    banner = ensure_ad_unit(app_id, "TankTime Banner", "BANNER")
    interstitial = ensure_ad_unit(app_id, "TankTime Interstitial", "INTERSTITIAL")
    banner_id = banner["adUnitId"]
    interstitial_id = interstitial["adUnitId"]
    validate_id(banner_id, "/")
    validate_id(interstitial_id, "/")

    result = {
        "publisherId": PUBLISHER_ID,
        "appId": app_id,
        "bannerId": banner_id,
        "interstitialId": interstitial_id,
        "appResource": app.get("name"),
        "createdAtUnix": int(time.time()),
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    print(f"PASS: TankTime AdMob inventory is ready. Saved private output to {OUT}.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise

