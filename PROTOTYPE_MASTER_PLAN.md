# Attention Prototype Master Plan

## Product Hypothesis
Attention helps users reduce reflexive social-media checking by measuring behavior, creating intentional pauses, rewarding better choices, and adapting goals over time.

## Shared Loop
```text
Attempt to access distracting app
→ Attention intervention
→ back out OR continue intentionally
→ record event
→ positive reinforcement
→ update goals / streak / score
```

## Shared Questions
1. Can the user select individual distracting apps?
2. Can Attention know when intervention should happen?
3. Can Attention create usable friction?
4. Can the user back out cleanly?
5. Can the user continue cleanly?
6. Can a meaningful usage session end be detected?
7. Can intervention intensity adapt?
8. What behavioral data is reliable?
9. Does behavior survive reboot/backgrounding/power management?
10. Is the approach plausibly store-distributable?

## Canonical Metric Fallback
```text
Exact App Opens
→ Distinct Sessions
→ Access Windows
→ Usage-Time Checkpoints
```
Never mislabel a lower-resolution signal as a higher-resolution one.

## Features That Survive Most Outcomes
Goals, XP, streaks, intentional choices, programs, recaps, historical trends, positive reinforcement.

## Red Lines
Rethink if selected apps cannot be targeted reliably, intervention UX is unusable, or meaningful behavioral signals beyond generic screen time are unavailable.

## Native Platforms
- iOS: Swift, SwiftUI, FamilyControls, ManagedSettings, DeviceActivity.
- Android: Kotlin, Jetpack Compose, UsageStats/UsageEvents and other platform mechanisms tested conservatively.

## Final Output
Complete each platform's `ARCHITECTURE_DECISION.md`, then root `docs/FINAL_PLATFORM_COMPARISON.md`.
