# P05 — Friction Ladder

**Goal:** escalate shield **copy** L0 → L1 → L2 from `continues_today` (per app or global — pick one and document; design plan default lean: per-app counts for level, budget global in P08). Never Mind does not bump Continue count. Levels work with host force-quit.

**User-visible change:** shield subtitle/tone hardens after repeated Continues the same local day. Reset-today debug control in a hidden/debug area OK.

**Prerequisite:** P03 PASS (ideally P04 so Continue→window→reshield cycle is easy).

**Agent rule:** escalate tone/stakes in copy only. **Do not** depend on a Continue-button delay API (unavailable). No XP awards here.

## Out of scope

- Today home metrics UI → **P06**
- XP/streaks → **P07**
- Daily Continue budget enforcement UX → **P08**

## Context

Lab M11: App Group shared state is trustworthy for levels; L2 delay unavailable.

Suggested mapping (show on debug screen):

- 0 Continues today → L0 soft pause  
- 1–2 → L1 reminder  
- ≥3 → L2 are-you-sure  

## Steps for the agent

1. Persist `continues_today` / `never_mind_today` + local day key in App Group (UUID-keyed).
2. ShieldConfiguration reads count → picks L0/L1/L2 product strings (no `shared OK` in shipping copy).
3. Increment Continue on Continue action; Never Mind increments intentional count only.
4. Day rollover clears counts; log `day_rollover`.
5. Fallback: if App Group unread → one static shield + `STATE_UNAVAILABLE` path logged; host still records events when possible.
6. Tag `ATTN-P05`.

## Agent exit checks

- [ ] Build succeeds
- [ ] Extension and host share the same suite
- [ ] No Continue-delay timer pretending to be an API feature

## Physical-device checklist (human)

- [ ] Continue 3× (re-shield between) → L0 then L1 then L2 visible on shield
- [ ] Force-quit host → open shielded app → level still correct
- [ ] Never Mind does not raise Continue level
- [ ] After local day change (or reset control) → back to L0
- [ ] Record trust: `trustworthy` / `fragile` / `unusable` in `PRODUCTION_RESULTS.md`

## Definition of done

- [ ] Visible L0–L2 adaptation on device
- [ ] Human confirmed force-quit persistence of level

**Next:** [P06 — Today Home](./MILESTONE_06_TODAY_HOME.md)
