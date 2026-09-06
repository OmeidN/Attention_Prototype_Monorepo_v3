# iOS Journal / Agent Context

Living notes for Cursor agents picking up this prototype with blank context.
**Read this before implementing the next milestone.** Canonical pass/fail table remains `docs/TEST_RESULTS.md`. Milestone specs remain in `milestones/`.

Last updated: 2026-09-06

---

## Where we are

| Item | Value |
|---|---|
| Current status | **M00–M02 PASS** on physical device |
| Next action | Implement **M03 — App Selection and Persistence** when human asks |
| Screen Time APIs in app | `AuthorizationCenter` only so far (Family Controls entitlement) |
| Extensions | None |
| App Group | Not enabled yet (planned `group.com.attention.apitest` from M03+) |
| Bundle id | `com.attention.apitest` |
| Entitlements | `AttentionAPITest/AttentionAPITest.entitlements` |
| Team ID | `VPG6W79282` |

Do **not** start M04+ until M03 passes on device. Do **not** treat `milestones/milestones-ios.md` as the active track — that file is an older MVP outline. The live sequence is `MILESTONE_00` … `MILESTONE_13`.

---

## Environment (confirmed)

- Mac: Apple silicon **M4**, local
- macOS: 26.6.2 (25G83)
- Xcode: 26.6 (17F113)
- iOS SDK: 26.5
- iPhone: **iPhone 17** / **iOS 26.6.1**
- Install: Xcode → USB → physical iPhone
- Apple Developer: paid program membership
- Team ID: `VPG6W79282`

Working agreement (also in `docs/DEV_ENVIRONMENT.md`): keep Xcode closed while Cursor edits; open Xcode only to sign, run, and test. Both writing `project.pbxproj` will conflict.

---

## Completed milestones

### M00 — Local Development Setup — PASS (2026-09-06)

**Goal:** prove local Mac + Xcode + USB install of a blank SwiftUI app. No Family Controls.

**Implemented:**
- Hand-authored Xcode project at `AttentionAPITest.xcodeproj`
- SwiftUI app entry `AttentionAPITest/AttentionAPITestApp.swift`
- Setup tab shows app name, milestone labels, ISO-8601 timestamp that updates on appear / scene active
- Lifecycle logging via `os.Logger` subsystem `attention.m00` and on-device `TestLogger` tags `ATTN-M00`
- No FamilyControls / ManagedSettings / DeviceActivity / App Groups / extra capabilities

**Device results (human confirmed):**
- App installed and ran on iPhone 17 over USB
- Setup device/OS/bundle info looked correct (`com.attention.apitest`)
- Timestamp updated after leaving the app and returning

---

### M01 — iOS Project Setup (experiment shell) — PASS (2026-09-06)

**Goal:** Setup / Experiments / Logs shell, TestLogger, ExperimentStore. Still no authorization.

**Implemented (bundled with M00 in the same build — agent was allowed to combine when still pre–Screen Time):**
- `RootView` — TabView with Setup, Experiments, Logs
- `SetupView` — milestone labels, M00 timestamp, device/build info, `foundation_ok`, explicit “Screen Time APIs: none yet”
- `ExperimentsView` — “M01 — no experiments yet” + button that writes a tagged log line
- `LogsView` — reverse-chronological list, Clear, Copy all
- `Shared/TestLogger.swift` — 500-line ring buffer, ISO-8601 timestamps, persisted in `UserDefaults` so process death does not wipe evidence
- `Shared/ExperimentStore.swift` — Bool/String get/set on `UserDefaults.standard` (App Group deferred until extensions)
- `Shared/DeviceInfo.swift` — hardware id, OS, bundle id, simulator vs physical flag
- On launch: `foundation_ok=true`, log `ATTN-M01 app_launched`

**Device results (human confirmed):**
- Three tabs work on physical device
- Writing a test log shows an `ATTN-M01` line with timestamp
- Logs persist across leave/return and until Clear
- Clear empties the list
- Copy all works
- Grep still shows zero Screen Time API usage (correct for this stage)

---

### M02 — Family Controls Authorization — PASS (2026-09-06)

**Goal:** Family Controls capability + individual authorization request, status on Setup, errors visible on-device.

**Implemented:**
- `AttentionAPITest/AttentionAPITest.entitlements` with `com.apple.developer.family-controls`
- `CODE_SIGN_ENTITLEMENTS` wired in Debug/Release
- `Shared/FamilyControlsAuth.swift` — status label + `requestAuthorization(for: .individual)`
- Setup section **M02 — Family Controls auth**: shows `notDetermined` / `denied` / `approved`, Request button, red on-screen error text
- Logs tagged `ATTN-M02` for status refresh, request start/success/failure
- Explicitly **no** `FamilyActivityPicker`, shields, or ManagedSettings writes

**Device results (human confirmed on iPhone 17):**
- Cold launch: `authorizationStatus=notDetermined`
- Tapped Request → system sheet completed
- `request_success status=approved` (log `2026-09-06T18:16:05.029Z`)
- No error text; Family Controls signing verified for local/dev use

---

## Key source map

```text
prototypes/ios/AttentionAPITest/
├── AttentionAPITest.xcodeproj/
├── AttentionAPITest/
│   ├── AttentionAPITestApp.swift   # @main, scene-phase logs, foundation_ok
│   ├── RootView.swift              # Setup / Experiments / Logs tabs
│   ├── SetupView.swift             # M00 timestamp + M02 auth UI
│   ├── ExperimentsView.swift       # log plumbing / future experiments
│   ├── LogsView.swift              # Clear / Copy / list
│   └── AttentionAPITest.entitlements  # Family Controls
├── Shared/
│   ├── TestLogger.swift
│   ├── ExperimentStore.swift
│   ├── DeviceInfo.swift
│   └── FamilyControlsAuth.swift    # M02 AuthorizationCenter wrapper
├── milestones/                     # M00–M13 agent specs (source of truth for next work)
├── docs/
│   ├── TEST_RESULTS.md             # pass/fail table
│   ├── DEV_ENVIRONMENT.md
│   └── ARCHITECTURE_DECISION.md    # fill after feasibility, not now
└── Journal-Context/                # this catch-up journal
```

---

## Settled platform facts (do not reverse)

From M00 spec / research — still relevant for M02+:

1. **`ApplicationToken` does not expose name/bundle ID** to app code in the classic path. User-typed labels after the picker (M03) are intentional UX. iOS 26.4+ may offer `FamilyActivityData.shared.installedApplications` with display names — M03 must probe and record; naming screen ships regardless.
2. **Token is not a reliable primary key.** Storage PK is our UUID; token is a live handle with refresh / picker re-bind fallback.
3. **Simulator is not valid for Screen Time PASS** from M02 onward.
4. This folder is a **feasibility lab**, not production MVP (no scoring engine, StoreKit, AI, backend).

SDK-only facts already noted in `TEST_RESULTS.md` (device must still confirm):
- DeviceActivity thresholds are **duration**-based, not open-count
- Whether report numbers are host-readable = UNKNOWN (M08)
- Token name readability on 26.4+ = UNKNOWN (M03)
- `ManagedSettings.Token.refresh` exists on 26.5+ 

---

## Explicitly not done

- M03 picker + naming + persistence
- M04+ shields, extensions, DeviceActivity, open detection, stress tests
- App Group capability
- Android (ignored in this journal; separate later)

---

## Instructions for the next agent

1. Read root `AGENTS.md`, `PROTOTYPE_MASTER_PLAN.md`, this file, then `milestones/MILESTONE_03_APP_SELECTION_AND_PERSISTENCE.md`.
2. Implement **M03 only** unless the human explicitly allows batching.
3. Stop when it builds; give physical-device test steps; do **not** mark PASS until the human confirms on the iPhone.
4. Update `docs/TEST_RESULTS.md` and append here when M03 is confirmed.
5. Do not modify Android.
