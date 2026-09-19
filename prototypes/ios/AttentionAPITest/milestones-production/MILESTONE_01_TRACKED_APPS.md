# P01 — Tracked Apps

**Goal:** let the user select distracting apps, name them, and persist them with **UUID primary keys**. Token is a refreshable handle. Support remove + re-bind.

**User-visible change:** Setup flow: open `FamilyActivityPicker` → name each app (required) → list of tracked apps with labels. Add / remove / Clear all. Refresh-token path reachable from UI.

**Prerequisite:** P00 PASS (auth approved on device).

**Agent rule:** implement this milestone only. Do not apply shields yet (P02). Do not invent bundle IDs or system display names.

## Out of scope

- Shield apply/clear → **P02**
- Shield extensions / Continue → **P03**
- Onboarding wizard polish → **P09** (this is functional Setup, not final onboarding)

## Context

Lab settled: `token_name_readable` unreliable; UUID + `userLabel` is PK. System picker checkboxes cannot be locked — reject adds that uncheck already-tracked tokens; remove only in-app.

## Steps for the agent

1. Model: `{ id: UUID, userLabel: String, token: ApplicationToken, dateAdded: Date }` in App Group (shared with future extensions).
2. UI: Add apps (picker) → naming screen (non-empty labels required, inline error) → persisted list.
3. Remove one / remove multiple / Clear all. Persist across relaunch.
4. `refreshToken(for:)` (or `ManagedSettings.Token.refresh` when available) + picker re-bind fallback. Surface “Re-bind” on a row.
5. Reject picker results that uncheck currently tracked tokens; explain on screen.
6. Log `ATTN-P01` with counts and ids (not raw token dumps).

## Agent exit checks

- [ ] Build succeeds
- [ ] Storage PK is UUID (grep shows no “token as dictionary key” for history)
- [ ] Blank label blocks continue on naming screen
- [ ] Data written to the product App Group suite

## Physical-device checklist (human)

- [ ] Add 1–2 apps; name them; relaunch — labels still there
- [ ] Add another without losing prior UUIDs
- [ ] Uncheck a tracked app in the system picker on add → rejected / explained
- [ ] Remove one app; multi-remove; Clear all
- [ ] Re-bind path runs without wiping UUID / history fields
- [ ] Record PASS/FAIL in `PRODUCTION_RESULTS.md`

## Definition of done

- [ ] Tracked apps persist with UUID + labels
- [ ] Token refresh / re-bind exists
- [ ] Human confirmed on device

**Next:** [P02 — Shield Apply / Clear](./MILESTONE_02_SHIELD_APPLY_CLEAR.md)
