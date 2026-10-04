# Market Hunter Validation — TankTime

Date: 2026-10-03
Country: US primary, FR localization secondary
Factory mode: App Factory Ads
Decision: CONTINUE ONLY WITH DIFFERENTIATED SCOPE

## Fresh targeted scan
A fresh Apple Search API scan was run for:
- propane runtime
- propane tank calculator
- rv propane calculator
- propane tank monitor
- propane fuel calculator

Exact runtime/calculator searches are weakly served by purpose-built apps. Results are mostly propane suppliers, hardware-linked tank monitors, generic calculators and RV utilities.

Demand signals in the adjacent propane-monitoring market are real:
- Nee-Vo: 7,298 US ratings in the `propane tank monitor` result set.
- MyPropane: 196 US ratings.
- Mopeka TankCheck: 72 US ratings.
- Tank Utility: 49 US ratings.

These products are primarily sensor/provider ecosystems, so a sensor-free planning workflow remains a different job-to-be-done.

## Direct competitor discovered
`Propane Trip Planner` is a recent $2.99 iPhone/iPad utility with substantial overlap: tank size, appliance BTU, daily use, trip length, reserve and required spare cylinders.

This invalidates the original thin concept as a generic single-appliance runtime worksheet. Shipping that scope would be too commodity-like and would weaken the Factory anti-spam / 4.3 gate.

## Self-challenge pass 1 — real user problem?
PASS. Community discussions repeatedly ask how long propane will last for RV furnaces, grills and cold-weather use, and answers vary because tank size, load, duty cycle and weather all matter. The problem is recurring and understandable without education-heavy onboarding.

## Self-challenge pass 2 — differentiated enough?
CURRENT THIN BUILD: FAIL.
PIVOTED BUILD: PASS WITH CONDITIONS.

Mandatory differentiators now being implemented:
- actual fuel remaining from scale weight minus tare
- saved tank profiles
- multi-appliance daily load planning, not one appliance at a time
- trip-duration + reserve planning from the user's current partially filled cylinder
- extra-cylinder requirement calculation
- metric + imperial support
- runtime history and shareable results
- offline/local-first operation

Do not copy the competitor's UI, wording, icon, screenshots or information architecture.

## Self-challenge pass 3 — monetization / review quality?
PASS WITH RELEASE GATES. Ads must not turn a quick utility into an interruption wall. Keep the banner unobtrusive and the interstitial cadence sparse. UMP must run before eligible ad requests. ATT and App Privacy must reflect the actual production Google Mobile Ads behavior, not an assumed configuration.

## Market Hunter verdict
TankTime is not approved as a bare propane-runtime calculator. It is approved to continue as a broader sensor-free propane planning utility centered on weighed fuel + multi-load trip planning + saved profiles/history.

Release remains blocked until:
- the differentiated planner passes CI and iPhone/iPad QA
- a unique TankTime icon/brand replaces the inherited placeholder
- production AdMob app/banner/interstitial IDs exist
- privacy/ATT audit is complete
- App Store screenshots and metadata reflect only shipped features
