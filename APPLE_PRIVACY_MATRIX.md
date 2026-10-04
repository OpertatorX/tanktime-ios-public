# TankTime — App Store Privacy Matrix

Updated: 2026-10-04
Status: ATT ENABLED; FINAL ARCHIVE RECONCILIATION STILL REQUIRED

## TankTime-owned data
TankTime has no account system and no OperatorX backend. Tank profiles, unit preferences, trip inputs and calculation history are stored locally in `UserDefaults` and are not sent to OperatorX.

The app-owned privacy manifest therefore keeps:
- `NSPrivacyTracking = false` for TankTime-owned local data;
- no TankTime-owned collected data types;
- UserDefaults required-reason API `CA92.1`.

## Google Mobile Ads 13.11.0 — inspected binary manifest
The exact `PrivacyInfo.xcprivacy` embedded in Google Mobile Ads 13.11.0 was downloaded from Google's official Swift Package binary and inspected locally.

It declares:
- Other Diagnostic Data: not linked, not tracking; Third-Party Advertising, Developer Advertising, Analytics.
- Coarse Location: linked; not tracking; Third-Party Advertising, Developer Advertising, Analytics.
- Performance Data: not linked, not tracking; Third-Party Advertising, Developer Advertising, Analytics.
- Crash Data: not linked, not tracking; Analytics.
- Advertising Data: linked; not tracking; Third-Party Advertising, Developer Advertising, Analytics.
- Product Interaction: linked; not tracking; Third-Party Advertising, Developer Advertising, Analytics.
- Device ID: linked and **used for tracking**; Third-Party Advertising, Developer Advertising, Analytics.
Required-reason API declarations in the Google Mobile Ads manifest:
- System Boot Time: `35F9.1`
- UserDefaults: `CA92.1`
- Disk Space: `E174.1`

## Google UMP 3.1.0 — inspected binary manifest
The official UMP 3.1.0 binary manifest declares:
- Coarse Location: not linked, not tracking; App Functionality.
- Performance Data: not linked, not tracking; App Functionality.
- Product Interaction: not linked, not tracking; App Functionality.
- UserDefaults required-reason API: `CA92.1`.

## ATT release posture
Because the embedded Google Mobile Ads manifest explicitly marks Device ID as linked and used for tracking, TankTime now includes App Tracking Transparency rather than relying on a no-tracking assumption.

Release behavior:
1. UMP updates consent information and presents required privacy forms.
2. If ads can be requested, TankTime requests ATT while the authorization status is `.notDetermined`.
3. TankTime waits for the ATT result before starting Google Mobile Ads.
4. If ATT is denied, ads can still be requested without the IDFA.
5. Publisher privacy personalization remains disabled and publisher first-party ID remains disabled.

The `NSUserTrackingUsageDescription` string is localized in English and French.
## App Store Connect questionnaire target
Before submission, the App Privacy answers should reflect the shipped Google SDK behavior, including the following categories at minimum:

| Apple category | Linked to user | Used for tracking | Purposes to declare/verify |
| --- | --- | --- | --- |
| Coarse Location | Yes (GMA) | No | Third-Party Advertising, Developer Advertising, Analytics; UMP also uses coarse location for App Functionality |
| Device ID | Yes | **Yes** | Third-Party Advertising, Developer Advertising, Analytics |
| Advertising Data | Yes | No | Third-Party Advertising, Developer Advertising, Analytics |
| Product Interaction | Yes (GMA) | No | Third-Party Advertising, Developer Advertising, Analytics; UMP App Functionality |
| Crash Data | No | No | Analytics |
| Performance Data | No (GMA) | No | Third-Party Advertising, Developer Advertising, Analytics; UMP App Functionality |
| Other Diagnostic Data | No | No | Third-Party Advertising, Developer Advertising, Analytics |

Target tracking answer: **Yes**, because Device ID is declared as used for tracking and TankTime now requests ATT before IDFA access.

## Final archive gate
Before review submission:
1. build with real AdMob IDs;
2. verify no Google test IDs exist in the archive;
3. verify the localized ATT usage description is bundled;
4. extract all embedded privacy manifests;
5. confirm the Google Mobile Ads Device ID tracking declaration is present as expected;
6. reconcile the archive privacy report with this matrix and current Google documentation;
7. complete/publish the App Store Connect App Privacy answers;
8. verify the public privacy policy matches the shipped behavior;
9. only then allow review submission.

Official references:
- https://developers.google.com/admob/ios/privacy/data-disclosure
- https://developers.google.com/admob/ios/privacy/strategies
- https://developers.google.com/admob/ios/privacy/ad-serving-modes
