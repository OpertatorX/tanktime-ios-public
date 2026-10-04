# TankTime — App Factory Ads Release Status

Updated: 2026-10-04
Current decision: KEEP BUILDING — differentiated scope validated

## PASS
- Native Swift + SwiftUI app, iPhone + iPad target.
- en-US + fr-FR localization.
- Multi-appliance propane trip planner.
- Weighed-fuel runtime calculator.
- Saved tanks + history + share flows.
- Metric + imperial support.
- Google Mobile Ads SDK 13.11.0 + UMP 3.1.0 integration.
- Publisher privacy personalization disabled and publisher first-party ID disabled.
- ATT is implemented and localized after direct inspection of the Google Mobile Ads 13.11.0 privacy manifest, which declares linked Device ID as used for tracking.
- Current Google + participating-buyer SKAdNetwork identifiers added to `Info.plist`.
- app-ads.txt live on the production website.
- EN/FR privacy, terms and support pages live.
- Market Hunter / Apple 4.3 differentiation challenge completed after product pivot.
- Debug and Release simulator builds plus unit tests previously passed on GitHub Actions.
- Release workflow blocks empty/test AdMob IDs and the inherited TrimBench icon.
- Release workflow captures final archive Info.plist + embedded privacy manifests for audit.
- Premium generated TankTime icon source is committed outside the app bundle at `artwork/TankTime-AppIconSource.jpg`; obsolete source/placeholder icon files were removed.
- Icon materialization enforces a fresh 1024×1024 RGB/no-alpha AppIcon before CI, screenshots, Xcode project export and Release.
- Generated `AppIcon-1024.png` is ignored by git so a stale icon cannot be accidentally committed as the release source.
- 20 real simulator screenshots automated for EN/FR, iPhone/iPad.
- Screenshot run `37182278964` completed successfully and produced the full 40-file raw + promotional artifact.
- Professional localized App Store screenshot renderer is installed for all 20 presentation images.
- Calculator, Planner and new-tank numeric fields keep persistent labels when values are populated.
- Built-in/sample tank names are localized in EN/FR.
- A consistent bronze TankTime accent is applied to native controls while retaining SwiftUI conventions.
- App Store screenshot uploader is automated through the App Store Connect API for EN/FR iPhone + iPad sets.
- App Store build selection and App Review submission automation is prepared.
- Zero-touch PowerShell release orchestrator is prepared for the authenticated Windows machine.
- App Store privacy matrix is based on direct inspection of the GMA 13.11.0 and UMP 3.1.0 embedded manifests; final archive reconciliation is still required.
- Apple bundle ID registered: `com.operatorx.tanktime`.
- Apple bundle resource ID: `JPYC8P5B36`.
- App Store Connect app ID: `6818814141`.
- Apple distribution certificate created for TankTime: `VD4UT585JK`.
- App Store provisioning profile created: `6JW3QXFP6R`.
- GitHub signing secrets installed.
- App Store Connect API secrets installed from the existing local AuthKey and verified against the live TankTime app.
- Direct Google SDK privacy manifest inspection completed: GMA Device ID is linked + tracking; UMP categories are non-tracking.
- ATT now runs after UMP consent and before Google Mobile Ads initialization; denial does not block app usage.
- Live App Store Connect audit confirms version 1.0 is PREPARE_FOR_SUBMISSION, FR/US metadata + support URLs are present, review contact/notes are populated, and no build is attached yet.
- Local Windows static audit passes JSON, Python automation, plist/privacy, 50 unique SKAdNetwork IDs, localization parity (76 keys), icon isolation and stale-brand/test-ID scans.
- Public App Store name accepted: `TankTime: Propane Planner`.
- EAS metadata project linked: `@operatorx/tanktime` (`4f12f7f8-b8f3-4dc8-a108-eeff7eaebb83`).
- Complete EN/FR `store.config.json` metadata package prepared.
- App Store Connect metadata, categories, age rating and review details synced successfully for version 1.0.

## ACTIVE AUTOMATION
- CI validates build, tests, non-personalized ad posture, SKAdNetwork coverage and icon generation.
- Screenshot workflow rebuilds the real app with the premium icon, captures 20 simulator screens, renders 20 promotional App Store images, and uploads them to App Store Connect when API secrets are present.
- Static Linux audit validates metadata/scripts/privacy/localization when GitHub-hosted runners are available.
- Recent macOS **and Ubuntu** jobs are failing before a runner is assigned (`runner_id = 0`, no steps executed). This is a hosted Actions allocation/account/infrastructure block, not a recorded TankTime compile/test failure.

## BLOCKED / MUST COMPLETE BEFORE RELEASE
- Create the production AdMob app + banner + interstitial units. Current bootstrap is blocked because no AdMob OAuth client/access token is configured; Google marks the create endpoints as limited-access, so a 403 may still require AdMob-console creation.
- Add the production AdMob IDs to GitHub release secrets.
- App Store Connect API secrets are installed; no blocker remains on ASC API authentication.
- Restore GitHub-hosted Actions execution so the final UI/icon CI + screenshot runs can execute. GitHub annotation now identifies the exact blocker: recent account payments failed or the Actions spending limit must be increased in Billing & plans.
- Reconcile the final production archive privacy manifests/report with App Store Connect privacy answers.
- Confirm AdMob Privacy & Messaging configuration is published for required regions.
- Run production Release, verify the processed build, upload final screenshots if not already automated, attach the build and submit for review.

## Signing / Apple state
- Two pre-existing iOS distribution certificates remain active through August 2027.
- TankTime has its own distribution certificate and App Store provisioning profile.
- No existing certificates or profiles were revoked.
- App Store Connect numeric app ID is `6818814141`.

## Hard release gates
Production Release must fail if Google test ad IDs are present, production ad IDs are empty, signing/API credentials are missing, the privacy posture disagrees with the production archive, or the generated release icon is missing/invalid/inherited.
