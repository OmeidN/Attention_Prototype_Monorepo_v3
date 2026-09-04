# M00 — Remote Development Setup

**Goal:** prove Windows → remote Mac → Xcode/Cursor/Git can produce a blank SwiftUI app. Record how a physical iPhone will be installed. No Family Controls.

**User-visible change:** on the Mac, a blank SwiftUI hello screen. On the phone, only if install is already possible this milestone.

**Prerequisite:** none. This is the first iOS milestone. Remote workflow: `docs/REMOTE_MAC_WORKFLOW.md`.

**Agent rule:** implement this milestone only. Stop when the blank app builds in Xcode (simulator is OK for M00). Do not mark PASS. Family Controls code is forbidden here.

## Settled platform facts (do not reverse later)

These apply from M03 onward. Record results in `docs/TEST_RESULTS.md` (there is no `feasibility-notes.md`).

1. **`ApplicationToken` never exposes name or bundle ID.** The only system UI that shows "TikTok" is Apple's `Label(token)`. We do **not** try to decode tokens. After the picker (M03), the user types their own label. That screen is intentional UX, not a hack to hide.
2. **`ApplicationToken` is not a reliable primary key.** Tokens can be silently reissued after OS/app updates. Storage PK is our own UUID. The token is a live handle with a `refreshToken(for:)` path.
3. Screen Time APIs largely do **not** behave in Simulator. M00 may use Simulator; **M02+ PASS requires a physical iPhone**.
4. This folder is a feasibility lab, not an XcodeGen/`AttentionCore`/scoring MVP. Do not add `project.yml`, a scoring engine, SwiftData product models, StoreKit, or AI.

## Out of scope

- AttentionAPITest experiment shell → **M01**
- Authorization, picker, shields, extensions → **M02+**
- Android changes
- Production onboarding, 7-day baseline, home/score UI, Pro, AI Coach

## Context

There is no iOS app source in this folder yet. Cloud Mac USB to a personal iPhone is often unavailable; treat host problems separately from Apple-API problems. If device install is TBD, document TBD — do not fake a device PASS.

## Steps for the agent

1. Create a local SwiftUI iOS app **AttentionAPITest** under `prototypes/ios/AttentionAPITest/` (Xcode project in-repo). Bundle id pattern: something like `com.attention.apitest` — record it in `docs/TEST_RESULTS.md`.
2. One screen: app name, `Milestone 00 — Remote Development Setup`, ISO-8601 timestamp updated on appear / scene active. Log the same events (`print` or `os.Logger` subsystem `attention.m00`).
3. No FamilyControls, ManagedSettings, DeviceActivity, App Groups, or extra capabilities.
4. Fill Mac-side TEST_RESULTS fields you can know (macOS, Xcode). Leave iPhone, signing, install method for the human if unknown.
5. Short note in `docs/REMOTE_MAC_WORKFLOW.md` if the actual path differs (local Mac vs cloud). Do not invent a provider.

## Agent exit checks

- [ ] Xcode build succeeds for a simulator destination
- [ ] Grep the new source for `FamilyControls`, `ManagedSettings`, `DeviceActivity` → zero hits
- [ ] Timestamp visible in the SwiftUI view

## Physical-device checklist (human)

- [ ] Record Mac provider, macOS, Xcode in `docs/TEST_RESULTS.md`
- [ ] Confirm Git on the Mac sees this repo
- [ ] Run on **iOS Simulator** at least once
- [ ] If a physical iPhone can be installed this week (local USB or other): run there and confirm the timestamp updates when returning to the app. Record model + iOS
- [ ] If physical install is not possible yet: write `install method: TBD` and **do not** mark device PASS — mark M00 as environment PASS only for Mac/simulator, with TBD called out
- [ ] Apple Developer status (paid account yes/no)

## Definition of done

- [ ] Blank SwiftUI app builds
- [ ] No Screen Time APIs
- [ ] Human recorded Mac/Xcode and install-method status

**Next:** [M01 — iOS Project Setup](./MILESTONE_01_PROJECT_SETUP.md)
