# iOS Journal / Agent Context

Living notes for Cursor agents picking up this prototype with blank context.
**Read this before implementing the next milestone.** Canonical pass/fail: `docs/TEST_RESULTS.md`.

Last updated: 2026-09-17

---

## Where we are

| Item | Value |
|---|---|
| Current status | **M00–M12 PASS**; **M13 verdict drafted — awaiting human confirmation** |
| Next action | Human reads/accepts `docs/ARCHITECTURE_DECISION.md`; no production app; no Android unless asked |
| Decision | **Access Window Model** (draft) |
| Extensions | ShieldConfiguration + ShieldAction + DeviceActivityMonitor + DeviceActivityReport |
| App Group | `group.com.attention.apitest` |
| Bundle id | `com.attention.apitest` |
| Team ID | `VPG6W79282` |

---

## Settled facts (do not reverse)

1. User-typed labels required (`token_name_readable` = NO).
2. UUID is PK; token is a handle; picker checkboxes cannot be locked.
3. Manual ManagedSettings shield works (force-quit + reboot).
4. Custom shield + Continue / Never Mind (`host_app_needed=no`).
5. **`threshold_unit=duration`**; **`not opens`**; report not host-readable.
6. Honest unit **`access_window`**; re-shield **`on_window_end`**.
7. Friction levels **trustworthy** (no Continue delay API).
8. Notifications suppressed while shielded (M12); full-day stress skipped.
9. **Do not start production** (scoring/home/Pro/AI) in this lab repo until M13 accepted.

---

## Completed

- M00–M12 PASS (M12 human 2026-09-17)
- M13 draft ARCHITECTURE_DECISION.md — Access Window Model

---

## Instructions

1. Do not mark M13 PASS until human accepts the architecture decision.
2. Do not build production features here.
3. Keep Xcode closed while editing. No Android unless asked.
