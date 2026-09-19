# P04 — Access Windows

**Goal:** Continue starts a timed **access window**. At window end, re-shield with production policy **`on_window_end`** and **`unsafe_interrupt=off`** (no mid-scroll yank). Support deferred re-shield when Attention is not active.

**User-visible change:** window length presets (e.g. 5 / 10 / 15 min + short debug). After Continue, user uses the app until end; then door closes again from Home (or when Attention returns).

**Prerequisite:** P03 PASS.

**Agent rule:** implement this milestone only. Do not ship `on_threshold` yank as default. Do not build friction ladder (P05) or XP (P07). Label honestly: `access_window` — never `session_end` / `open`.

## Out of scope

- L0–L2 copy → **P05**
- Goals/XP → **P07**
- Hard-mode threshold yank → optional later / not default

## Context

Lab M09–M10: access window is the honest unit; `on_window_end` is the production candidate; deferred re-shield when host backgrounded is expected.

## Steps for the agent

1. On Continue: write `access_window_start` + `access_window_end_at` to App Group; start host timer / scheduling plan.
2. Settings or Setup: duration presets; default short (e.g. 5 or 10 min).
3. At end: if Attention active/safe → apply shield for that app (or all tracked per policy — document choice; prefer re-shield the window’s app + ensure tracked set consistent).
4. If Attention background/quit at end: log `window_end_while_foreground deferred=…` / deferred path; re-shield when Attention becomes active.
5. Leave/return inside window → still unshielded.
6. Log `window_end` event with mechanism (`timer` / `host_deferred_on_attention_active`).
7. Tag `ATTN-P04`. Show policy on screen: `on_window_end`, unsafe off.

## Agent exit checks

- [ ] Build succeeds
- [ ] Continue path sets end timestamp
- [ ] No default mid-use yank code path enabled
- [ ] Logs never call timer expiry `open` or `session_end`

## Physical-device checklist (human)

- [ ] Continue → usable inside window
- [ ] Leave/return inside window → still unshielded
- [ ] After end + Attention open → reshielded from Home (no requirement to yank mid-scroll)
- [ ] Force-quit Attention during window → deferred re-shield when Attention reopened
- [ ] Short debug duration and a real preset both work
- [ ] Record policy confirmation in `PRODUCTION_RESULTS.md`

## Definition of done

- [ ] Access window + safe re-shield on device
- [ ] Deferred path confirmed
- [ ] Human confirmed

**Next:** [P05 — Friction Ladder](./MILESTONE_05_FRICTION_LADDER.md)
