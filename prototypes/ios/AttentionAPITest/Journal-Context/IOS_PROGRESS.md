# iOS Journal / Agent Context

Living notes for Cursor agents picking up this prototype with blank context.
**Read this before implementing the next milestone.** Canonical pass/fail: `docs/TEST_RESULTS.md`.

Last updated: 2026-09-07 (restored M06+M07 after accidental undo)

---

## Where we are

| Item | Value |
|---|---|
| Current status | **M00–M06 PASS** on physical device; **M07 implemented — awaiting device confirmation** (or finish checklist if already partially tested) |
| Next action | Human: Xcode Run → M07 physical-device checklist; do not start M08 until M07 PASS |
| Extensions | ShieldConfiguration + ShieldAction + DeviceActivityMonitor |
| App Group | `group.com.attention.apitest` |
| Bundle id | `com.attention.apitest` |
| Team ID | `VPG6W79282` |

---

## Settled facts (do not reverse)

1. User-typed labels required (`token_name_readable` = NO).
2. UUID is PK; one-at-a-time add; cannot lock picker checkboxes.
3. Manual ManagedSettings shield works and survives reboot (M04).
4. Custom shield chrome FULL (M05); App Group A/B works.
5. **Shield actions:** Never Mind / Continue work **without** Attention in foreground (`host_app_needed=no`). Continue clears that app’s shield token and returns `.close` → backs out; **extra Home tap** to open. After Continue, stays unshielded until manual re-shield (M10).
6. Host-seen latency (~10s sample) is “open Attention later,” not Continue→unblock latency.
7. **SDK:** `DeviceActivityEvent.threshold` is `DateComponents` only → **duration**, not opens. Device must confirm callbacks.

---

## Completed (high level)

- **M00–M05 PASS**
- **M06 PASS (2026-09-06):** Never Mind / Continue; force-closed OK; Continue = dismiss + unblock (not auto-open)
- **M07 code restored:** monitor extension + 1-min per-app events + Start/Stop UI. **Not PASS until human confirms.**

---

## Problems / noise

- CFPrefs App Group warnings — ignore if store_backing shows App Group
- FamilyControlsAgent helper noise on name probe — expected NO path
- ShellSceneKit ProfileActivation decode noise — system
- **2026-09-07:** accidental undo wiped uncommitted M06/M07; restored from chat. Prefer committing after each milestone PASS.

---

## Instructions for next agent

1. If human reports M07 results → update TEST_RESULTS + this file; M08 only when asked.
2. Keep Xcode closed while editing. Do not modify Android.
3. Never call a duration threshold an `open`.
