# M00 — Local Development Setup

**Goal:** prove the local Mac + Xcode + Cursor + Git can produce a blank SwiftUI app and install it on the physical iPhone over USB. Record the environment. No Family Controls.

**User-visible change:** a blank SwiftUI screen with an ISO-8601 timestamp, running on the iPhone.

**Prerequisite:** none. This is the first iOS milestone. Environment record: `docs/DEV_ENVIRONMENT.md`.

**Agent rule:** implement this milestone only. Stop when the blank app builds. Do not mark PASS. Family Controls code is forbidden here.

## Settled platform facts (do not reverse later)

These apply from M03 onward. Record results in `docs/TEST_RESULTS.md` (there is no `feasibility-notes.md`).

1. **`ApplicationToken` never exposes name or bundle ID.** The only system UI that shows "TikTok" is Apple's `Label(token)`. We do **not** try to decode tokens. After the picker (M03), the user types their own label. That screen is intentional UX, not a hack to hide.
   - **Amendment (iOS 26.4+, verify on device):** `FamilyControls.FamilyActivityData.shared.installedApplications` returns `[ManagedSettings.Application]`, and `Application` carries `bundleIdentifier` and `localizedDisplayName` alongside `token`. If that resolves on the test device, fact 1 is superseded **on iOS 26.4 and later only**. M03 probes this and records the result. The naming screen ships regardless — it is the correct design and the only path on earlier iOS.
2. **`ApplicationToken` is not a reliable primary key.** Tokens can be silently reissued after OS/app updates. Storage PK is our own UUID. The token is a live handle with a `refreshToken(for:)` path. iOS 26.5 adds an official `ManagedSettings.Token.refresh(_:)` — use it when available, keep the picker re-bind fallback.
3. Screen Time APIs largely do **not** behave in Simulator. M00/M01 may use Simulator to prove compilation; **M02+ PASS requires a physical iPhone**.
4. This folder is a feasibility lab, not an XcodeGen/`AttentionCore`/scoring MVP. Do not add `project.yml`, a scoring engine, SwiftData product models, StoreKit, or AI.

## Out of scope

- AttentionAPITest experiment shell → **M01**
- Authorization, picker, shields, extensions → **M02+**
- Android changes
- Production onboarding, 7-day baseline, home/score UI, Pro, AI Coach

## Context

There is no iOS app source in this folder yet. Development is local: Apple silicon Mac, Xcode, physical iPhone over USB, paid Apple Developer Program membership. There is no remote-host variable to disentangle, so a build or install failure is either a signing problem or an Apple-API problem — say which. Device install is expected in this milestone, not deferred.

The Xcode project is hand-authored in-repo (no XcodeGen, per fact 4) using Xcode 16+ synchronized file groups, so folders map to targets and new source files need no project-navigator step.

## Steps for the agent

1. Create a SwiftUI iOS app **AttentionAPITest** under `prototypes/ios/AttentionAPITest/` (Xcode project in-repo). Bundle id pattern: something like `com.attention.apitest` — record it in `docs/TEST_RESULTS.md`.
2. One screen: app name, `Milestone 00 — Local Development Setup`, ISO-8601 timestamp updated on appear / scene active. Log the same events (`print` or `os.Logger` subsystem `attention.m00`).
3. No FamilyControls, ManagedSettings, DeviceActivity, App Groups, or extra capabilities.
4. Fill Mac-side TEST_RESULTS fields you can know (macOS, Xcode, SDK). Leave iPhone model, iOS version, and signing result for the human.
5. Record the real environment in `docs/DEV_ENVIRONMENT.md`.

## Agent exit checks

- [ ] Build succeeds from the command line for an iOS destination
- [ ] Grep the new source for `FamilyControls`, `ManagedSettings`, `DeviceActivity` → zero hits
- [ ] Timestamp visible in the SwiftUI view

## Physical-device checklist (human)

- [ ] Xcode > Settings > Accounts shows the paid team
- [ ] iPhone connected over USB, **Trust This Computer** accepted, phone unlocked
- [ ] Developer Mode enabled on the iPhone (Settings > Privacy & Security > Developer Mode — this reboots the phone)
- [ ] Signing team selected on the app target; the app installs to the iPhone
- [ ] Run on the iPhone and confirm the timestamp updates when returning to the app
- [ ] Record macOS, Xcode, iPhone model, iOS version, and bundle id in `docs/TEST_RESULTS.md`
- [ ] Confirm Git sees this repo (`git status` is clean of surprises)

## Definition of done

- [ ] Blank SwiftUI app builds
- [ ] No Screen Time APIs
- [ ] App installed and running on the physical iPhone
- [ ] Human recorded Mac, Xcode, iPhone, and iOS version

**Next:** [M01 — iOS Project Setup](./MILESTONE_01_PROJECT_SETUP.md)
