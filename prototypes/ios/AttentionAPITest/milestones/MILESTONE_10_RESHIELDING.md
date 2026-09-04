# M10 — Re-shielding

**Goal:** test clean re-shield at session end, at access-window end, and at a usage threshold. **Reject** arbitrary interruption of active use unless the human explicitly wants that experiment and it is labeled unsafe.

**User-visible change:** three named modes on Experiments (only one armed): `on_window_end`, `on_threshold`, `manual_only`. Logs which mode fired.

**Prerequisite:** M09 window exists.

**Agent rule:** default mode must not pull the rug while the selected app is foreground. If you implement a "hard interrupt" debug switch, default it **off** and label it `unsafe_interrupt`.

## Out of scope

- Dynamic intensity copy → **M11**
- Stress matrix → **M12**

## Context

Re-shielding too early feels broken; too late fails the product. Apple will not give a perfect "user left Instagram" event. Window-end while backgrounded is the conservative production candidate.

## Steps for the agent

1. Modes as above. Log `reshield_mode`, `reshield_applied_at`, `reason`.
2. `on_window_end`: if selected app is not in the foreground (best-effort: main app is active, or you cannot know — then only re-shield when host becomes active after end). Document the limitation.
3. `on_threshold`: DeviceActivity event → write flag → apply shield (from extension if possible, else next main-app launch — log delay).
4. Never Mind leaves shield on (already on). Continue enters the window then re-shields per mode.
5. Tag `ATTN-M10`.

## Agent exit checks

- [ ] Build succeeds
- [ ] Unsafe interrupt is off by default
- [ ] Re-shield reasons logged

## Physical-device checklist (human)

- [ ] Window-end while you are **in** the selected app: were you interrupted? (default should be no)
- [ ] Window-end after you left: next open is shielded
- [ ] Threshold mode: after 1 minute of use, next open (or current, if unsafe on) matches the logged reason
- [ ] Rapid reopen around window end (5 times) — flicker/double shield?
- [ ] Record which mode is acceptable for production
- [ ] PASS = modes measured

## Definition of done

- [ ] Re-shield modes implemented and labeled
- [ ] Active-use interrupt is not the default
- [ ] Human recorded acceptable mode

**Next:** [M11 — Dynamic Interventions](./MILESTONE_11_DYNAMIC_INTERVENTIONS.md)
