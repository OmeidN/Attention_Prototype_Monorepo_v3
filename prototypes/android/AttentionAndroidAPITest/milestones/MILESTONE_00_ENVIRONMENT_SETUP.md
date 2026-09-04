# M00 — Android Environment Setup

**Goal:** prove this Windows machine can build and run a blank Kotlin + Compose app on a physical phone. No usage or intervention APIs.

**User-visible change:** a one-screen app that shows its name, this milestone, and a live `onResume` timestamp.

**Prerequisite:** none. This is the first Android milestone.

**Agent rule:** implement this milestone only. Stop after `assembleDebug` succeeds. Do not mark PASS. Give the human the physical-device steps below.

> A blank Compose app already exists at `prototypes/android/AttentionAndroidAPITest` (`:app` only). Do not recreate the project. Do not add `core/` or `usagestats/` modules unless a later milestone explicitly needs them. Verify, complete gaps, and stop.

## Settled platform facts (do not reverse later)

1. **Android is not iOS.** `PackageManager` gives real `loadLabel` and `loadIcon`. There is no sealed `ApplicationToken`. **Do not port iOS's "type the app name yourself" screen.** An optional nickname later is fine; it must never block selection the way iOS naming does.
2. **`packageName` is a stable identity key** (plus a row `UUID` and `dateAdded`). Unlike iOS, you may key by package name.
3. `UsageStatsManager` is inconsistent on emulators. **M00+ PASS for API work needs a physical device.** Prefer more than one OEM before trusting numbers (Pixel, Samsung, Xiaomi when available — missing OEM = `not tested`).
4. This is a feasibility lab. Do not add a scoring engine, Room product schema, Play Billing, or AI. Record in `docs/TEST_RESULTS.md`.

## Out of scope

- Setup / Experiments / Logs tabs, TestLogger, export → **M01**
- Package enumeration, Usage Access, interventions → **M02+**
- iOS, backend, auth, analytics, production UI / home score / 7-day baseline

## Context

`MainActivity.kt` already shows three lines of text and logs `onCreate` / `onResume` to Logcat under `ATTN-M00`. `docs/TEST_RESULTS.md` has Studio/Gradle/Kotlin filled in; the physical-device row is still empty. USB debugging and a real-phone run have not been confirmed.

## Steps for the agent

1. Confirm the project is Kotlin + Compose, `minSdk 26`, `applicationId com.attention.androidapitest`.
2. Keep the blank screen: app name, `Milestone 00 — Environment Setup`, and `Last onResume: <ISO-8601>`. Update the timestamp in `onResume`.
3. Keep `Log.i("ATTN-M00", ...)` on `onCreate` and `onResume`. No UsageStats, no extra permissions, no second Activity.
4. Fill only machine-side fields in `docs/TEST_RESULTS.md` (Windows, Studio, AGP, Kotlin, emulator presence). Leave device / USB / PASS blank for the human.
5. Run `.\gradlew.bat assembleDebug` from this prototype folder.

## Agent exit checks

```text
.\gradlew.bat assembleDebug
```

- [ ] Debug APK builds
- [ ] `AndroidManifest.xml` has no `PACKAGE_USAGE_STATS`, overlay, or accessibility
- [ ] Grep `src/` for `UsageStats`, `AccessibilityService`, `SYSTEM_ALERT_WINDOW` → zero hits
- [ ] On-screen timestamp and `ATTN-M00` Logcat tag still present

## Physical-device checklist (human)

- [ ] Open the project in Android Studio and let Gradle sync
- [ ] Enable Developer options + USB debugging on the phone; authorize the PC
- [ ] Run the app on the **physical phone** (not only the emulator)
- [ ] Confirm the three lines of text and that `Last onResume` updates when you leave and return
- [ ] In Logcat, filter `ATTN-M00` and confirm `onCreate` / `onResume` lines with timestamps
- [ ] Record phone model, Android version, manufacturer, and USB-debugging result in `docs/TEST_RESULTS.md`
- [ ] Mark M00 PASS or FAIL there. The agent must not do this for you

## Definition of done

- [ ] Blank Compose app builds
- [ ] Timestamp + Logcat instrumentation present
- [ ] No later-milestone APIs
- [ ] Human recorded physical-device evidence in `docs/TEST_RESULTS.md`

**Next:** [M01 — Prototype Foundation](./MILESTONE_01_PROJECT_FOUNDATION.md)
