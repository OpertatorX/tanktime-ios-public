# TankTime Privacy / ATT Audit

Date: 2026-10-04
Release posture: Google Mobile Ads + UMP + ATT, with publisher ad personalization disabled and publisher first-party ID disabled.

## App-owned data
TankTime has no account system and no OperatorX backend. Tank profiles, appliance presets, unit preference, plan inputs and calculation history remain in local UserDefaults storage.

App-owned privacy manifest:
- `NSPrivacyTracking = false` for TankTime-owned data;
- no TankTime-owned collected data types;
- UserDefaults required-reason API: `CA92.1`.

## Direct SDK manifest audit
The official Google Mobile Ads 13.11.0 and UMP 3.1.0 binary packages were downloaded and their embedded `PrivacyInfo.xcprivacy` files inspected locally.

Google Mobile Ads 13.11.0 declares Device ID as linked to the user and used for tracking for third-party advertising, developer advertising and analytics. It also declares coarse location, advertising data, product interaction, crash data, performance data and other diagnostic data with their corresponding purposes.

UMP 3.1.0 declares coarse location, performance data and product interaction for App Functionality, all non-tracking.

Full field-by-field mapping is in `APPLE_PRIVACY_MATRIX.md`.
## ATT flow
TankTime now includes a localized `NSUserTrackingUsageDescription` and imports `AppTrackingTransparency`.

The startup order is:
1. refresh UMP consent information;
2. present any required UMP consent form;
3. require `ConsentInformation.shared.canRequestAds`;
4. if ATT is still undetermined, request tracking authorization;
5. wait for the ATT callback;
6. start Google Mobile Ads and load ads.

If the user denies ATT, TankTime remains usable and Google Mobile Ads can request ads without receiving the IDFA. Personalized ad treatment remains disabled.

## App Store Connect disclosure gate
Before submission:
1. build the production archive with real AdMob IDs;
2. inspect every embedded privacy manifest and the generated privacy report;
3. set App Store Connect Tracking to **Yes** and disclose Device ID as linked/used for tracking unless the final archive and shipped configuration prove otherwise;
4. disclose the remaining Google/UMP data categories documented in `APPLE_PRIVACY_MATRIX.md`;
5. verify the public EN/FR privacy policy matches the shipped ATT and Google Ads behavior;
6. publish the required AdMob Privacy & Messaging forms;
7. only then attach the build and submit for review.

Release is blocked if the production archive, AdMob configuration, privacy policy and App Store Connect answers disagree.
