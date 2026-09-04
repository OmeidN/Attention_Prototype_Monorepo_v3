# Android Prototype Plan

## Objective
Determine whether Android can support Attention's intervention loop reliably, safely, and in a plausibly distributable way.

## Prototype Rule
Technical possibility is not enough. For powerful APIs, record reliability, permission burden, background behavior, OEM variation, and Google Play policy/distribution implications.

## Candidate Mechanisms
- UsageStatsManager / UsageEvents
- Usage Access permission
- foreground/session inference
- installed-app/package selection with minimal package visibility
- lifecycle/background components where appropriate
- notifications where appropriate
- AccessibilityService only as an isolated later experiment if justified
- overlay permission only as an isolated later experiment if justified
- battery optimization/background restriction testing

Do not jump directly to Accessibility or overlays before measuring simpler mechanisms.

## Critical Unknowns
Foreground/session accuracy, event latency, intervention timing, Continue/Never Mind navigation, background survival, reboot recovery, OEM battery behavior, Play policy compatibility.

## Fallback
Open → Session → Access Window → Usage-Time.

A technically successful approach with serious Play-policy risk must be labeled `TECHNICAL PASS / DISTRIBUTION RISK`, not a clean pass.
