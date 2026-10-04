#!/usr/bin/env python3
from __future__ import annotations
import argparse, base64, json, os, sys, time
from pathlib import Path
import jwt, requests

API = 'https://api.appstoreconnect.apple.com'
BUNDLE_RESOURCE_ID = 'JPYC8P5B36'
BUNDLE_ID = 'com.operatorx.tanktime'
LEGACY_PROFILE_ID = '6JW3QXFP6R'
LEGACY_CERT_ID = 'VD4UT585JK'
CI_PROFILE_NAME = 'TankTime App Store CI'

def bearer() -> str:
    key = base64.b64decode(os.environ['ASC_API_KEY_BASE64']).decode('utf-8')
    now = int(time.time())
    return jwt.encode({'iss': os.environ['ASC_ISSUER_ID'], 'iat': now, 'exp': now + 900, 'aud': 'appstoreconnect-v1'}, key, algorithm='ES256', headers={'kid': os.environ['ASC_KEY_ID'], 'typ': 'JWT'})

TOKEN = bearer()

def api(method, path, *, params=None, body=None, expected=(200, 201, 204)):
    r = requests.request(method, API + path, params=params, json=body, headers={'Authorization': f'Bearer {TOKEN}', 'Content-Type': 'application/json'}, timeout=60)
    if r.status_code not in expected:
        raise RuntimeError(f'{method} {path} -> {r.status_code}: {r.text[:1600]}')
    return None if r.status_code == 204 else r.json()

def list_profiles():
    return api('GET', '/v1/profiles', params={'limit': 200}).get('data', [])

def profile_bundle_id(profile_id: str) -> str:
    return api('GET', f'/v1/profiles/{profile_id}/bundleId')['data']['id']

def profile_cert_ids(profile_id: str) -> list[str]:
    data = api('GET', f'/v1/profiles/{profile_id}/relationships/certificates').get('data', [])
    return [item['id'] for item in data]

def delete_profile_and_linked_cert(profile_id: str, *, require_cert: str | None = None):
    if profile_bundle_id(profile_id) != BUNDLE_RESOURCE_ID:
        raise RuntimeError(f'Refusing to delete profile {profile_id}: wrong bundle ID')
    cert_ids = profile_cert_ids(profile_id)
    if require_cert and cert_ids != [require_cert]:
        raise RuntimeError(f'Refusing to delete profile {profile_id}: unexpected certificates {cert_ids}')
    api('DELETE', f'/v1/profiles/{profile_id}')
    for cert_id in cert_ids:
        api('DELETE', f'/v1/certificates/{cert_id}')
        print('Revoked dedicated TankTime certificate', cert_id)
    print('Deleted dedicated TankTime profile', profile_id)

def cleanup_stale():
    for profile in list_profiles():
        name = profile.get('attributes', {}).get('name', '')
        if name == CI_PROFILE_NAME:
            delete_profile_and_linked_cert(profile['id'])

def prepare(csr_path: Path, out_dir: Path):
    cleanup_stale()
    legacy = [p for p in list_profiles() if p['id'] == LEGACY_PROFILE_ID]
    if legacy:
        delete_profile_and_linked_cert(LEGACY_PROFILE_ID, require_cert=LEGACY_CERT_ID)
    csr = csr_path.read_text(encoding='utf-8')
    cert = api('POST', '/v1/certificates', body={'data': {'type': 'certificates', 'attributes': {'certificateType': 'IOS_DISTRIBUTION', 'csrContent': csr}}})['data']
    cert_id = cert['id']
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / 'distribution.cer').write_bytes(base64.b64decode(cert['attributes']['certificateContent']))
    profile_body = {'data': {'type': 'profiles', 'attributes': {'name': CI_PROFILE_NAME, 'profileType': 'IOS_APP_STORE'}, 'relationships': {'bundleId': {'data': {'type': 'bundleIds', 'id': BUNDLE_RESOURCE_ID}}, 'certificates': {'data': [{'type': 'certificates', 'id': cert_id}]}}}}
    try:
        profile = api('POST', '/v1/profiles', body=profile_body)['data']
    except Exception:
        api('DELETE', f'/v1/certificates/{cert_id}')
        raise
    profile_id = profile['id']
    (out_dir / 'TankTime.mobileprovision').write_bytes(base64.b64decode(profile['attributes']['profileContent']))
    state = {'certificateId': cert_id, 'profileId': profile_id, 'profileName': CI_PROFILE_NAME, 'bundleId': BUNDLE_ID}
    (out_dir / 'signing-state.json').write_text(json.dumps(state, indent=2) + '\n', encoding='utf-8')
    print('PASS: ephemeral TankTime signing assets created', cert_id, profile_id)

def cleanup():
    cleanup_stale()
    print('PASS: stale TankTime CI signing assets cleaned.')

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('mode', choices=['prepare', 'cleanup'])
    parser.add_argument('--csr')
    parser.add_argument('--out-dir', default='artifacts/signing')
    args = parser.parse_args()
    if args.mode == 'prepare':
        if not args.csr: raise SystemExit('--csr is required for prepare')
        prepare(Path(args.csr), Path(args.out_dir))
    else: cleanup()

if __name__ == '__main__':
    try: main()
    except Exception as exc:
        print(f'ERROR: {exc}', file=sys.stderr)
        raise
