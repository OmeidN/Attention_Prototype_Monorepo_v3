# P05A — Hard Threshold Re-shield (Set-and-Forget)

**Goal:** make the **default closer** a DeviceActivity **usage-duration** threshold that re-shields from the **monitor extension** even when Attention is force-quit. Per-app window length. User is told they may be yanked mid-use.

**User-visible change:** Apps tab shows policy “hard threshold / may yank,” per-app (or editable) window length, and a clear warning. After Continue, ~N minutes of use → shield returns without opening Attention.

**Prerequisite:** P04–P05 PASS (windows + friction). Human accepts set-and-forget + yank over gentle host deferral.

**Agent rule:** implement this milestone only. Do not build Today home (P06), XP (P07), or full onboarding (P09) — but put yank honesty on the Apps screen. Honest labels: usage duration / access window — not opens, not exact wall-clock.

## Out of scope

- Leave-app detection (unavailable)  
- Today home / XP → **P06–P07**  
- Full onboarding wizard → **P09** (extend copy there later)  
- Claiming exact stopwatch timing  

## Context

P04 proved host `on_window_end` + deferred re-shield. That fails set-and-forget (Attention rarely opened). Lab `on_threshold` proved the monitor extension can re-shield while the host is dead (may yank). Product default flips to that path.

```text
Continue → unblock + arm usage threshold (~window length)
→ user uses app (Attention may be quit)
→ eventDidReachThreshold → extension re-shields (possible mid-use yank)
```

## Steps for the agent

1. Default `ReshieldPolicy` → `on_threshold` (document yank). Keep host timer as optional/non-primary.
2. Per-app `windowDurationSeconds` on tracked apps (default from shared presets: 15s debug / 1 / 5 / 10 / 15 min).
3. On Continue (ShieldAction): unblock, write window state, **re-arm** DeviceActivity monitoring so the threshold can fire again (once-per-interval lab fact).
4. Monitor extension: on threshold, re-shield that app (existing `tryReshieldFromMonitorExtension` path).
5. Apps UI: policy line, yank warning, per-app duration controls, monitoring status / last threshold from App Group.
6. Tag `ATTN-P05A`. Copy: “about N minutes of use,” not “exactly N:00.”

## Agent exit checks

- [ ] Build succeeds (host + shield action + monitor extension)
- [ ] Default mode is `on_threshold`
- [ ] Continue path re-arms monitoring
- [ ] No “open” / “session_end” labeling for threshold fire

## Physical-device checklist (human)

- [ ] Set a short window (15s or 1 min) on a tracked app; Shield all
- [ ] Continue → use app → shield returns **without** reopening Attention (force-quit Attention after Continue)
- [ ] Yank mid-use is acceptable / observed
- [ ] Second Continue same day still eventually re-shields (re-arm works)
- [ ] Per-app duration change affects next window
- [ ] Record trust / timing notes in `PRODUCTION_RESULTS.md`

## Definition of done

- [ ] Hard re-shield works with Attention dead
- [ ] Yank disclosed in UI
- [ ] Human confirmed on device

**Next:** [P06 — Today Home](./MILESTONE_06_TODAY_HOME.md)
