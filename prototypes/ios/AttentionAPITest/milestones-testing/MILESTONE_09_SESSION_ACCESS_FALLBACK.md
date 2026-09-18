# M09 — Session / Access Fallback

**Goal:** if exact opens failed, test the next honest units: distinct sessions, Continue-triggered **access windows**, cooldowns, usage checkpoints. Choose the highest-resolution reliable unit.

**User-visible change:** after Continue, a visible window (15s debug / 1 min / 5 min). Logs for window start/end. Optional "usage checkpoint" when a DeviceActivity threshold fires inside or after the window.

**Prerequisite:** M06 Continue works at least sometimes. M08 trial recorded.

**Agent rule:** implement this milestone only. Do not implement clever mid-use interruption (M10). Conservative labels.

## Out of scope

- Re-shield timing matrix → **M10** (this milestone may re-apply shield at window end; M10 owns session-end vs interrupt)
- Dynamic copy → **M11**
- Stress/failure → **M12**

## Context

If iOS cannot see launches, Attention can still: lift shield for N minutes (access window), or wait for a usage threshold (usage-time). Distinct "sessions" may be indistinguishable from windows. Pick the honest name.

## Steps for the agent

1. Experiments: window length picker. On Continue (M06), write `access_window_end_at` to App Group and start a plan to **re-apply shield at end**.
2. Re-apply using `ManagedSettingsStore` from the **main app** if a timer in-app is the only reliable tool; also try extension/DeviceActivity if you already have it. Log which mechanism actually re-shielded.
3. If the user is still in the app when the window ends, do **not** yank them mid-scroll in this milestone — log `window_end_while_foreground` and wait until next offer (M10 decides). Show this rule on screen.
4. Usage checkpoint: reuse M07-style 1-minute event as `usage_checkpoint` logs, labeled as usage-time not session end.
5. Tag `ATTN-M09`.

## Agent exit checks

- [ ] Build succeeds
- [ ] Window start/end logged
- [ ] Timer expiry is not labeled `open` or `session_end` unless you have a real end signal

## Physical-device checklist (human)

- [ ] Continue → stay in app inside window → still usable
- [ ] Continue → leave app, return inside window → still unshielded
- [ ] After window, app is shielded again (from Home, not necessarily torn down mid-use)
- [ ] 15s debug window vs 1 min — both behave
- [ ] Notes: honest unit `session` / `access_window` / `usage_time`
- [ ] Record in TEST_RESULTS

## Definition of done

- [ ] Access window after Continue
- [ ] Human chose the fallback unit

**Next:** [M10 — Re-shielding](./MILESTONE_10_RESHIELDING.md)
