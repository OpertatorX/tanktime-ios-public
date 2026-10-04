#!/usr/bin/env python3
import base64, os, time
import jwt, requests
API = 'https://api.appstoreconnect.apple.com'
key = base64.b64decode(os.environ['ASC_API_KEY_BASE64']).decode('utf-8')
now = int(time.time())
token = jwt.encode({'iss': os.environ['ASC_ISSUER_ID'], 'iat': now, 'exp': now + 900, 'aud': 'appstoreconnect-v1'}, key, algorithm='ES256', headers={'kid': os.environ['ASC_KEY_ID'], 'typ': 'JWT'})
headers = {'Authorization': f'Bearer {token}'}
def get(path, params=None):
    r = requests.get(API + path, headers=headers, params=params, timeout=30)
    print(path, r.status_code)
    if r.status_code != 200:
        print(r.text[:1200]); raise SystemExit(2)
    return r.json().get('data', [])
certs = get('/v1/certificates', {'filter[certificateType]': 'DISTRIBUTION', 'limit': 200})
print('DISTRIBUTION_CERT_COUNT', len(certs))
for c in certs:
    a = c.get('attributes', {})
    print('CERT', c.get('id'), a.get('displayName'), a.get('serialNumber'), a.get('expirationDate'), a.get('activated'))
bundles = get('/v1/bundleIds', {'filter[identifier]': 'com.operatorx.tanktime', 'limit': 10})
print('BUNDLE_IDS', [(b.get('id'), b.get('attributes', {}).get('identifier')) for b in bundles])
profiles = get('/v1/profiles', {'filter[name]': 'TankTime App Store', 'limit': 50})
print('PROFILE_COUNT', len(profiles))
for p in profiles:
    a = p.get('attributes', {})
    print('PROFILE', p.get('id'), a.get('name'), a.get('profileState'), a.get('expirationDate'))
print('PASS: provisioning API access is available.')
