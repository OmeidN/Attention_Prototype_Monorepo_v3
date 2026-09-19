# P10 — Usage Checkpoint (Optional)

**Goal:** optional DeviceActivity **duration** threshold as a **side signal** only — e.g. log / soft insight “you’ve been in for ~1 min”. Must not become the main loop or be labeled as opens/sessions.

**User-visible change:** Settings toggle. When on, a usage checkpoint can appear in Logs / Today insights. Default may be off for v1 dogfood.

**Prerequisite:** P04 access windows working. Settings shell from P08.

**Agent rule:** `threshold_unit=duration` only. If monitoring is flaky, fail soft and document — do not block v1 spine. Skip DeviceActivityReport UI.

## Out of scope

- Making checkpoints gate Continue or yank mid-use → forbidden as default  
- Report API dashboards → forbidden  
- Stress/dogfood → **P11**

## Context

Lab M07: duration thresholds fire; once per event per interval until restart. Useful as coarse checkpoint, not open detection.

## Steps for the agent

1. DeviceActivityMonitorExtension schedule for tracked apps when toggle enabled.
2. On `eventDidReachThreshold`: write `usage_checkpoint` event with timestamp + app id/label; log `ATTN-P10`.
3. Today / Logs: show as “usage checkpoint” — never “open”.
4. Toggle off → stop monitoring cleanly.
5. If extension cannot run, surface `checkpoint_unavailable` on Settings.

## Agent exit checks

- [ ] Build succeeds with monitor extension (if toggle-on path ships)
- [ ] Grep user-facing strings: checkpoint not called open/session
- [ ] Main loop (shield → choice → window) does not require checkpoints

## Physical-device checklist (human)

- [ ] Toggle on → after ~1 min in a Continue window (or per schedule), checkpoint logs
- [ ] Toggle off → no new checkpoints
- [ ] Untracked apps do not falsely checkpoint
- [ ] Record reliability note in `PRODUCTION_RESULTS.md` (or SKIP with reason)

## Definition of done

- [ ] Optional side signal works or is explicitly SKIPPED with reason
- [ ] Human confirmed labeling honesty

**Next:** [P11 — Dogfood Reliability](./MILESTONE_11_DOGFOOD_RELIABILITY.md)
