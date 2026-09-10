# iOS Journal / Agent Context

Living notes for Cursor agents picking up this prototype with blank context.
**Read this before implementing the next milestone.** Canonical pass/fail: `docs/TEST_RESULTS.md`.

Last updated: 2026-09-09

---

## Where we are

| Item | Value |
|---|---|
| Current status | **M00–M08 PASS**; **M09 built — awaiting device** |
| Next action | Human runs M09 access-window checklist; no M10 until M09 PASS |
| Extensions | ShieldConfiguration + ShieldAction + DeviceActivityMonitor + DeviceActivityReport |
| App Group | `group.com.attention.apitest` |
| Bundle id | `com.attention.apitest` |
| Team ID | `VPG6W79282` |

---

## Settled facts (do not reverse)

1. User-typed labels required (`token_name_readable` = NO).
2. UUID is PK; one-at-a-time add; cannot lock picker checkboxes.
3. Manual ManagedSettings shield works and survives reboot (M04).
4. Custom shield chrome FULL (M05); App Group A/B works.
5. Shield actions: Continue = `.close` + unblock; extra Home tap; `host_app_needed=no` (M06).
6. **`threshold_unit=duration`** (M07). Once-per-event-per-interval.
7. **`not opens` (M08)** — no validated launch/open signal. Report display-only; host cannot read report numbers.
8. **M09 in progress:** Continue starts `access_window` (App Group `access_window_end_at`). Host re-shields via timer / deferred on Attention active. Do not label timer expiry as `open` or `session_end`. Mid-use yank = M10.

---

## Completed

- M00–M08 PASS (M08 human 2026-09-09, verdict `not opens`)
- M09 code: access window bridge, host timer, Continue wire, usage_checkpoint hook

---

## Instructions

1. Do not mark M09 PASS until human records window + honest unit.
2. Keep Xcode closed while editing. No Android.
