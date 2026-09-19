# P02 — Shield Apply / Clear

**Goal:** apply and clear ManagedSettings shields for all (or selected) tracked application tokens. Prove persistence across Attention force-quit and device reboot.

**User-visible change:** **Shield all** / **Clear shields** on Setup or Home. Tracked apps show blocked by the system (Apple default chrome OK). Untracked apps open normally.

**Prerequisite:** P01 PASS (at least one named tracked app).

**Agent rule:** implement this milestone only. Custom Never Mind / Continue chrome is **P03**. Do not start access windows.

## Out of scope

- Custom shield UI / actions → **P03**
- Timed re-shield → **P04**
- Friction levels → **P05**

## Context

Lab M04: `ManagedSettingsStore.shield.applications` is reliable through force-quit and reboot. Product v1 uses the same mechanism as the intervention door.

## Steps for the agent

1. Wire Shield all → set `shield.applications` to the current tracked token set.
2. Clear shields → empty / nil the set.
3. After tracked-app list changes, keep shield set consistent (shield newly added if “shielding active”; drop removed).
4. Show shielding state on screen (`active` / `cleared`) + last apply timestamp.
5. Log `ATTN-P02` apply/clear with labels + ids.
6. Optional: “Pause Attention” stub that clears shields with a warning string — full Pause UX lands in P08; here a clear button is enough.

## Agent exit checks

- [ ] Build succeeds
- [ ] Apply/clear code paths exist against ManagedSettingsStore
- [ ] No ShieldConfiguration/Action required yet (Apple default shield OK)

## Physical-device checklist (human)

- [ ] Shield all → open tracked app → blocked
- [ ] Untracked app opens normally
- [ ] Clear shields → tracked app opens
- [ ] Force-quit Attention → tracked app still shielded
- [ ] Reboot → tracked app still shielded
- [ ] No “leaks” (apps that should be blocked aren’t openable)
- [ ] Record in `PRODUCTION_RESULTS.md`

## Definition of done

- [ ] Apply/clear reliable on device
- [ ] Human confirmed force-quit + reboot persistence

**Next:** [P03 — Shield Loop and Events](./MILESTONE_03_SHIELD_LOOP_AND_EVENTS.md)
