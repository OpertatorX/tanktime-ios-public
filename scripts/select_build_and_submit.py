#!/usr/bin/env python3
from __future__ import annotations

import base64
import os
import sys
import time

import jwt
import requests

API = "https://api.appstoreconnect.apple.com"
APP_ID = os.environ.get("ASC_APP_ID", "6818814141")
VERSION = os.environ.get("ASC_VERSION", "1.0")
KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
KEY_B64 = os.environ["ASC_API_KEY_BASE64"]
SUBMIT = os.environ.get("SUBMIT_FOR_REVIEW", "0") == "1"


def token() -> str:
    private_key = base64.b64decode(KEY_B64).decode("utf-8")
    now = int(time.time())
    return jwt.encode(
        {"iss": ISSUER_ID, "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"},
        private_key,
        algorithm="ES256",
        headers={"kid": KEY_ID, "typ": "JWT"},
    )


BEARER = token()


def api(method: str, path: str, *, params=None, json=None, expected=(200, 201, 204)):
    response = requests.request(
        method,
        API + path,
        params=params,
        json=json,
        headers={"Authorization": f"Bearer {BEARER}", "Content-Type": "application/json"},
        timeout=60,
    )
    if response.status_code not in expected:
        raise RuntimeError(f"{method} {path} -> {response.status_code}: {response.text[:1600]}")
    return None if response.status_code == 204 else response.json()


def get_store_version() -> dict:
    payload = api(
        "GET",
        f"/v1/apps/{APP_ID}/appStoreVersions",
        params={"filter[platform]": "IOS", "filter[versionString]": VERSION, "limit": 10},
    )
    data = payload.get("data", [])
    if not data:
        raise RuntimeError(f"No iOS App Store version {VERSION} found for app {APP_ID}")
    return data[0]


def get_prerelease_version_id() -> str:
    payload = api(
        "GET",
        "/v1/preReleaseVersions",
        params={"filter[app]": APP_ID, "filter[platform]": "IOS", "filter[version]": VERSION, "limit": 20},
    )
    data = payload.get("data", [])
    if not data:
        raise RuntimeError(f"No iOS pre-release version {VERSION} found")
    return data[0]["id"]


def wait_for_latest_valid_build(timeout_seconds: int = 900) -> dict:
    pre_id = get_prerelease_version_id()
    deadline = time.time() + timeout_seconds
    last_states: list[str] = []
    while time.time() < deadline:
        payload = api(
            "GET",
            "/v1/builds",
            params={"filter[preReleaseVersion]": pre_id, "sort": "-uploadedDate", "limit": 20},
        )
        builds = payload.get("data", [])
        last_states = [f"{b['attributes'].get('version')}:{b['attributes'].get('processingState')}" for b in builds[:5]]
        valid = [b for b in builds if b["attributes"].get("processingState") == "VALID"]
        if valid:
            return valid[0]
        print(f"Waiting for processed build: {last_states or ['none yet']}")
        time.sleep(20)
    raise TimeoutError(f"No VALID build appeared for {VERSION}; last states: {last_states}")


def attach_build(store_version_id: str, build_id: str) -> None:
    api(
        "PATCH",
        f"/v1/appStoreVersions/{store_version_id}/relationships/build",
        json={"data": {"type": "builds", "id": build_id}},
        expected=(200, 204),
    )


def current_version_state(store_version_id: str) -> str:
    item = api("GET", f"/v1/appStoreVersions/{store_version_id}")["data"]
    attrs = item.get("attributes", {})
    return attrs.get("appVersionState") or attrs.get("appStoreState") or "UNKNOWN"


def create_review_submission(store_version_id: str) -> str:
    created = api(
        "POST",
        "/v1/reviewSubmissions",
        json={
            "data": {
                "type": "reviewSubmissions",
                "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
            }
        },
    )["data"]
    submission_id = created["id"]
    api(
        "POST",
        "/v1/reviewSubmissionItems",
        json={
            "data": {
                "type": "reviewSubmissionItems",
                "relationships": {
                    "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": store_version_id}},
                },
            }
        },
    )
    return submission_id


def submit_review(submission_id: str) -> None:
    api(
        "PATCH",
        f"/v1/reviewSubmissions/{submission_id}",
        json={
            "data": {
                "type": "reviewSubmissions",
                "id": submission_id,
                "attributes": {"submitted": True},
            }
        },
    )


def main() -> int:
    store_version = get_store_version()
    store_version_id = store_version["id"]
    build = wait_for_latest_valid_build()
    build_id = build["id"]
    build_number = build["attributes"].get("version", "?")
    print(f"Selected latest VALID build {build_number} ({build_id})")
    attach_build(store_version_id, build_id)
    print(f"PASS: build {build_number} attached to App Store version {VERSION}")

    state = current_version_state(store_version_id)
    print(f"App Store version state after build attachment: {state}")
    if not SUBMIT:
        print("SUBMIT_FOR_REVIEW is not 1; stopping safely after build selection.")
        return 0

    submission_id = create_review_submission(store_version_id)
    print(f"Created review submission {submission_id}")
    submit_review(submission_id)
    print("PASS: review submission sent to Apple.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise
