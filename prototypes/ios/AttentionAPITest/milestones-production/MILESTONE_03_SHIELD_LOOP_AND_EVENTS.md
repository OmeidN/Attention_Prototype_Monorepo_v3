# P03 — Shield Loop and Events

**Goal:** ship product Shield Configuration + Shield Action extensions. **Never Mind** stays blocked and logs an intentional choice. **Continue** clears that app’s shield, closes the shield UI, and logs a continue event. Append-only event records go to the App Group for later host ingest.

**User-visible change:** custom shield titled `Attention — {userLabel}` with **Never Mind** / **Continue**. Buttons work with Attention force-quit (`host_app_needed=no`).

**Prerequisite:** P02 PASS.

**Agent rule:** implement this milestone only. Do **not** start timed access windows or automatic re-shield (P04). Do **not** award XP (P07). After Continue, app may stay unshielded until manual Shield all — that is expected until P04.

## Out of scope

- Access windows / re-shield policy → **P04**
- L0–L2 friction copy → **P05** (static product copy OK here)
- Today home / XP → **P06–P07**

## Context

Lab M05–M06: custom chrome + actions work; Continue = unblock + `.close` (extra Home tap to open — no auto-launch API). Events must key by tracked-app **UUID**, not raw token.

## Steps for the agent

1. Add ShieldConfigurationExtension + ShieldActionExtension (Family Controls + App Group on each).
2. Configuration: title `Attention — {userLabel}` (lookup token → UUID → label); primary **Never Mind**, secondary **Continue**; product copy (no lab `shared OK` debug in shipping subtitle — put debug behind a flag or Logs screen).
3. Never Mind: keep shield; write event `{ type: intentional_choice, trackedAppId, timestamp }`; `.close`.
4. Continue: remove that app’s token from shield set; write `{ type: continue, trackedAppId, timestamp }`; `.close` (document extra tap).
5. Host: last action + latency note when host next becomes active; do not require host for the action itself.
6. Log `ATTN-P03`. Ensure extensions build and embed correctly.

## Agent exit checks

- [ ] Host + both shield extensions build
- [ ] Events keyed by UUID
- [ ] Grep for access-window timer / `access_window_end_at` → zero hits (P04)
- [ ] Grep for XP / streak awards → zero hits (P07)

## Physical-device checklist (human)

Repeat several times:

- [ ] Never Mind → still blocked; not inside the app
- [ ] Continue → can enter app after expected extra tap; record tap count
- [ ] Force-quit Attention → Never Mind / Continue still work
- [ ] Event visible in App Group / host “last action” UI after reopen
- [ ] After Continue, stays unshielded until manual Shield (note for P04)
- [ ] Record in `PRODUCTION_RESULTS.md`

## Definition of done

- [ ] Both actions work on device without host foreground
- [ ] Intentional choice + continue events recorded
- [ ] Human confirmed

**Next:** [P04 — Access Windows](./MILESTONE_04_ACCESS_WINDOWS.md)
