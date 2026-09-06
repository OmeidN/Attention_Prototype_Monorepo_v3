# iOS Journal / Agent Context

Living notes for Cursor agents picking up this prototype with blank context.
**Read this before implementing the next milestone.** Canonical pass/fail table remains `docs/TEST_RESULTS.md`. Milestone specs remain in `milestones/`.

Last updated: 2026-09-06

---

## Where we are

| Item | Value |
|---|---|
| Current status | **M00–M03 PASS** (incl. one-at-a-time add / remove). **M04 implemented — BUILDS, awaiting device** |
| Next action | Human: M04 shield apply/clear checklist on iPhone |
| Screen Time APIs in app | Auth + picker + `ManagedSettingsStore` default shield (no custom shield extensions) |
| Extensions | None |
| App Group | `group.com.attention.apitest` |
| Bundle id | `com.attention.apitest` |
| Entitlements | Family Controls + App Groups |
| Team ID | `VPG6W79282` |

Do **not** start M05 until M04 passes on device. Do **not** treat `milestones/milestones-ios.md` as the active track. Live sequence: `MILESTONE_00` … `MILESTONE_13`.

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

Working agreement: keep Xcode **closed** while Cursor edits; open only to sign, run, and test.

---

## Problems hit and fixes (read this)

### Workflow
- **Xcode left open during agent edits:** risky for `project.pbxproj` / entitlements clobber.
- **CLI `xcodebuild` hung on CodeSign** — compile-check with `CODE_SIGNING_ALLOWED=NO`; signed install via Xcode ▶ Run.
- **App Groups** needed provisioning refresh for `group.com.attention.apitest`.

### M02
- Yellow warning **Family Controls (Development) vs Distribution** — expected for local USB.

### M03 — naming sheet frozen / blank (fixed)
- Picker dismiss + immediate `.sheet` race; fragile `$labels[index]`.
- **Fix:** deferred `.sheet(item: NamingSession)` + draft bindings.

### M03 — token display names (device fact)
- Probe **NO** — helper communication failure; user-typed labels required.

### M03 — one-at-a-time add + stable UUIDs (fixed + device PASS)
- Old replace-all minted new UUIDs every save.
- **Now:** append one new app; existing ids/labels persist. Human confirmed.

### M03 — cannot lock Apple picker checkboxes (device PASS)
- No API to lock checks. **Reject** add if tracked apps unchecked; **Remove** is in-app (swipe / multi-select / Clear all). Human confirmed.

### Noise to ignore
- `The variant selector cell index number could not be found` during system picker.

---

## Completed milestones

### M00 — PASS · M01 — PASS · M02 — PASS
See earlier journal history / `TEST_RESULTS.md`. Shell + Family Controls individual auth approved on device.

### M03 — App Selection, Naming, Persistence — PASS (2026-09-06)

**Core + follow-ups confirmed on device:**
- UUID-keyed App Group store; naming; name probe NO
- One-at-a-time add (stable UUIDs when adding another app)
- Uncheck-tracked during add → rejected
- Remove one / multi-remove / Clear all

### M04 — Basic Shielding — BUILDS (awaiting device, 2026-09-06)

**Goal:** manual apply/clear of Apple’s **default** system shield on tracked apps. Red-line: can we block selected apps?

**Implemented:**
- `Shared/ShieldController.swift` — `ManagedSettingsStore().shield.applications` from tracked tokens
- Experiments: **Shield selected: &lt;userLabels&gt;** / **Clear shield**
- On-screen `shielded: yes/no` from **last successful write** (not OS readback)
- Logs `ATTN-M04` `shield_apply` / `shield_clear` with labels + ids
- Clear all tracked apps also clears shield
- **No** ShieldConfiguration / ShieldAction / DeviceActivity extensions

**Device checklist (human):**
1. Open Xcode → ▶ Run; have ≥1 named tracked app
2. Experiments → **Shield selected: …** → status shows shielded yes
3. From Home, open each tracked app → default system shield (not the app)
4. Open an untracked app → should launch normally
5. **Clear shield** → tracked apps open normally
6. Shield on → force-quit Attention → tracked app still shielded?
7. Shield on → reboot → still shielded? Record yes/no
8. Note any leaks (app opens despite shield)

---

## Key source map

```text
prototypes/ios/AttentionAPITest/
├── AttentionAPITest/
│   ├── ExperimentsView.swift       # M03 manage apps + M04 shield buttons
│   ├── NamingAppsView.swift
│   └── AttentionAPITest.entitlements
├── Shared/
│   ├── TrackedAppsStore.swift
│   ├── ShieldController.swift      # M04
│   ├── FamilyControlsAuth.swift
│   ├── TokenNameProbe.swift
│   └── …
└── Journal-Context/IOS_PROGRESS.md
```

---

## Settled platform facts (do not reverse)

1. User-typed labels required (`token_name_readable` = NO on this device).
2. UUID is PK; token is live handle with picker re-bind.
3. One-at-a-time add; picker Set order is not trustworthy.
4. Cannot lock FamilyActivityPicker checkboxes — reject + in-app remove.
5. Simulator not valid for Screen Time PASS from M02+.
6. Feasibility lab only — no production MVP extras.

---

## Explicitly not done

- M04 device PASS
- M05+ custom shield / actions / DeviceActivity / open detection
- Family Controls Distribution entitlement
- Android

---

## Instructions for the next agent

1. If M04 awaiting device: wait for human confirmation before M05.
2. After M04 PASS: read `milestones/MILESTONE_05_CUSTOM_SHIELD.md`.
3. One milestone at a time unless human allows batching.
4. Never mark PASS until human confirms on iPhone.
5. Update `TEST_RESULTS.md` + this journal on confirm.
6. Do not modify Android. Keep Xcode closed while editing.
