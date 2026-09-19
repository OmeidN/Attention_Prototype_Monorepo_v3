# P08 — Settings and Budget

**Goal:** user-facing Settings for window duration, daily Continue budget (global for v1 unless human picked per-app), and **Pause Attention** (clear shields) with a loud warning. Wire budget remaining onto Home; over-budget still allows Continue but copy already escalates via P05.

**User-visible change:** Settings screen; Home shows Continues remaining today; Pause Attention confirms before clearing shields.

**Prerequisite:** P04–P07.

**Agent rule:** do not hard-lock Continue in v1 (shield must stay usable). Budget is reinforcement + friction, not lockout. Do not add StoreKit.

## Out of scope

- Full onboarding wizard → **P09**
- Distribution entitlement paperwork → **P12**
- Hard-mode mid-use yank toggle → omit or bury experimental; default stays safe

## Context

Open decisions from design plan to resolve here (record in `PRODUCTION_RESULTS.md`):

1. Global vs per-app Continue budget → **default global**
2. Default window length + whether editable mid-day → **default editable**
3. Pause Attention existence → **yes, with warning**

## Steps for the agent

1. Settings: window presets, Continue budget (e.g. 3–5), optional usage-checkpoint toggle stub (wired in P10).
2. Persist settings to App Group where extensions/host both need them (window length for P04).
3. Home: `continues_remaining = budget - continues_today` (floor at 0 display).
4. Pause Attention: confirm sheet explaining shields lift until resumed; clear shields; log `attention_paused`.
5. Resume / Shield all restores protection.
6. Tag `ATTN-P08`.

## Agent exit checks

- [ ] Build succeeds
- [ ] Window length change affects next Continue window
- [ ] Pause clears shields in code
- [ ] Continue still available at L2 when budget is 0

## Physical-device checklist (human)

- [ ] Change window length → next Continue uses new duration
- [ ] Hit budget → Home shows 0 remaining; Continue still works; L2 copy still OK
- [ ] Pause Attention → tracked apps open; Resume → shielded again
- [ ] Record budget/global choice in `PRODUCTION_RESULTS.md`

## Definition of done

- [ ] Settings drive real behavior
- [ ] Pause path confirmed safe/clear
- [ ] Human confirmed

**Next:** [P09 — Onboarding](./MILESTONE_09_ONBOARDING.md)
