# iOS Journal / Agent Context

Living notes for Cursor agents picking up this prototype with blank context.
**Read this before implementing the next milestone.** Canonical pass/fail: `docs/TEST_RESULTS.md`.

Last updated: 2026-09-09

---

## Where we are

| Item | Value |
|---|---|
| Current status | **M00–M08 PASS** |
| Next action | Implement **M09** (session / access-window fallback) — one milestone only |
| Extensions | ShieldConfiguration + ShieldAction + DeviceActivityMonitor + DeviceActivityReport (ExtensionKit → `App/Extensions/`) |
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
7. **`not opens` (M08)** — no validated launch/open signal. Report = display-only; host cannot read report numbers; side-channel write failed on device; host `activityData` sandboxed. M07 thresholds ≠ launches. Do not call pickups/thresholds opens.
8. Canonical product fallback ladder: Opens → Sessions → **Access Windows** → Usage-Time. M09 owns the next honest unit.

---

## Completed

- M00–M08 PASS (M08 human 2026-09-09, verdict `not opens`)

---

## Instructions

1. Do not start M10 until M09 PASS on device.
2. Never label signals as opens/session_end without evidence.
3. Keep Xcode closed while editing. No Android.
