# iOS Journal / Agent Context

Living notes for Cursor agents picking up this prototype with blank context.
**Read this before implementing the next milestone.** Canonical pass/fail: `docs/TEST_RESULTS.md`.

Last updated: 2026-09-14

---

## Where we are

| Item | Value |
|---|---|
| Current status | **M00–M09 PASS**; **M10 built — awaiting device** |
| Next action | Human runs M10 mode checklist; no M11 until M10 PASS |
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
7. **`not opens` (M08)** — no validated launch/open signal.
8. **Honest unit = `access_window` (M09)**.
9. **M10 in progress:** reshield modes `on_window_end` / `on_threshold` / `manual_only`; `unsafe_interrupt` default OFF.

---

## Completed

- M00–M09 PASS (M09 human 2026-09-14, honest unit `access_window`)
- M10 code: mode picker, unsafe toggle, threshold extension path, manual button

---

## Instructions

1. Do not mark M10 PASS until human records modes + acceptable production mode.
2. Keep Xcode closed while editing. No Android.
