# App Factory Ads — Run 2026-10-03

Status: ACTIVE
Mode: APP_FACTORY_ADS
Project: TankTime
Bundle ID: com.operatorx.tanktime
Platform: iOS / iPadOS 17+
Stack: Swift 6 + SwiftUI + XcodeGen
Monetization: Free + AdMob banner/interstitial
Languages: fr-FR + en-US
Data model: local-first, no account, no backend

## Market decision
Selected wedge: sensor-free propane/LPG remaining-fuel, runtime and trip planning for grills, patio heaters, RV/camping, portable heaters and generators.

Shipped core jobs:
- estimate fuel remaining from current scale weight minus cylinder tare weight;
- estimate runtime from appliance BTU draw or a custom power override;
- calculate days of use from daily operating hours;
- combine multiple appliances into a trip fuel plan with duration and reserve;
- estimate extra full cylinders and optional fuel cost;
- save reusable cylinder profiles;
- save runtime calculation history locally;
- share runtime and fuel-plan summaries;
- switch between imperial and metric units.

Rejected during research: utility meter tracker, generator maintenance, pressure-washer calculator, towing payload calculator, tile calculator, compressed-air sizing.
Reason: current App Store results already contained close substitutes or weaker differentiation, increasing Apple 4.3/spam risk.

## Mandatory self-challenge 1 — Is this a clone?
PASS WITH CONDITIONS. Hardware-monitor apps require proprietary sensors; TankTime does not. A direct propane trip-planner competitor was found, so the thin calculator concept was rejected and the scope was expanded around scale-weight fuel estimation + multi-appliance planning + saved cylinder profiles/history. Do not copy competitor UI, wording, iconography or information architecture.

## Mandatory self-challenge 2 — Is the app deep enough for review?
PASS WITH FINAL QA GATE. The implemented product has two distinct workflows (single-appliance runtime and multi-appliance trip planning), saved cylinder profiles, six appliance presets, custom power override, calculation history, share flows, metric/imperial support, FR/US localization, iPhone/iPad layouts, privacy/settings screens and locally persisted user data.

No unimplemented feature may be claimed in metadata or screenshots. TankTime currently does **not** claim sensor connectivity, refill logging, push/local refill notifications, accounts, subscriptions or cloud sync.

## Mandatory self-challenge 3 — Does Ads mode stay compliant?
PASS WITH RELEASE GATE. Use Google Mobile Ads via SPM, UMP before eligible ad requests, Google test IDs in Debug/simulator tooling only, and production IDs in Release only. The current release disables ad personalization and publisher first-party ID. ATT is added only if the final production configuration qualifies as tracking; App Privacy must match the shipped SDK/configuration exactly.

## Hard release gates
- No production archive while an AdMob production App ID/banner/interstitial ID is missing.
- No Google test ad ID in Release.
- No ad request before UMP has completed the required consent flow.
- No fake/demo buttons or placeholder-only production features.
- No public metadata/screenshot claim for a feature not present in the shipping binary.
- Apple 4.3 differentiation review repeated against the final feature set and screenshots.
- Production archive privacy manifests/report reconciled with App Store Connect privacy answers before review submission.
