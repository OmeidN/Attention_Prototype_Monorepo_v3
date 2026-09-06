# iOS Journal / Agent Context

Living notes for Cursor agents picking up this prototype with blank context.
**Read this before implementing the next milestone.** Canonical pass/fail table remains `docs/TEST_RESULTS.md`. Milestone specs remain in `milestones/`.

Last updated: 2026-09-06

---

## Where we are

| Item | Value |
|---|---|
| Current status | **M00–M05 PASS** on physical device |
| Next action | Implement **M06 — Shield Actions and Continue UX** when human asks |
| Screen Time APIs | Auth + picker + ManagedSettings + **ShieldConfigurationExtension** (FULL) |
| Extensions | ShieldConfiguration only (no ShieldAction yet) |
| App Group | `group.com.attention.apitest` |
| Bundle id | `com.attention.apitest` |
| Team ID | `VPG6W79282` |

Do **not** start M07 until M06 passes on device.

---

## Environment (confirmed)

- Mac: Apple silicon **M4** · macOS 26.6.2 · Xcode 26.6 · iPhone 17 / iOS 26.6.1
- Working agreement: Xcode closed while Cursor edits

---

## Problems hit and fixes (summary)

- Naming sheet freeze → deferred `sheet(item:)` (M03)
- Token names unreadable → user labels (M03)
- One-at-a-time add + in-app remove; cannot lock picker checkboxes
- M04: must tap **Shield selected**; shield survives reboot
- M05: App Group shared state works (`shared OK`); A/B flips without rebuild

---

## Completed milestones

### M00–M04 — PASS
See `TEST_RESULTS.md`.

### M05 — Custom Shield — PASS · **FULL** (2026-09-06)

**Device evidence (screenshots):**
- Title: `Attention — Gram` (userLabel from App Group)
- Subtitle A: `Variant A: pause before opening. (shared OK)`
- Subtitle B: `Variant B: intentional choice check. (shared OK)`
- Flip A↔B in host app → reopen shielded app → copy updates without rebuild
- Buttons: **Never Mind** (primary) / **Continue** (secondary)
- Icon: hourglass SF Symbol visible
- Outcome: **FULL** (fields appear as coded; not stuck on default system-only shield)
- Button taps not handled yet → **M06**

---

## Instructions for the next agent

1. Read `milestones/MILESTONE_06_SHIELD_ACTIONS_AND_CONTINUE_UX.md`.
2. Implement **M06 only** unless human allows batching.
3. Stop when it builds; physical-device steps; no PASS until human confirms.
4. Do not modify Android. Keep Xcode closed while editing.
