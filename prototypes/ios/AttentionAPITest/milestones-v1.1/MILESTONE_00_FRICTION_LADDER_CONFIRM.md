# V11-00 — Friction ladder confirm

**Goal:** prove on the current TestFlight/Xcode install that shield copy actually moves L0 → L1 → L2 from **today’s Continue events on that app**. This is the leftover from v1 criterion 4. The read path is already in `InterventionState.continueCount` (max of stored count and `TodayEventLog` continues today) and `ShieldConfigurationExtension`.

**User-visible change:** none unless the device check **fails**. Then fix shield-level reads only.

**Prerequisite:** v1 freeze accepted. Dogfood/TestFlight 0.1 (3) or a later overlay of the same code.

**Agent rule:** do **not** implement this milestone as new product work first. Give the human the steps. Only write code if they report still-L0 after 2 Continues. Do not touch `HardWindowMonitor`, `ReshieldPolicy`, or the monitor extension.

## Out of scope

- Never Mind “win” copy → **V11-01**
- Home / Settings / Recap layout → **V11-02**
- StoreKit / Free–Pro → later (not laid out)

## Expected mapping (already shipped)

| Continues today (this app) | Level | Shield subtitle (approx) | Continue button |
|---|---|---|---|
| 0 | L0 | Pause a beat. What did you come here for? | Continue |
| 1–2 | L1 | You've continued already today. Still intentional? | Continue |
| ≥3 | L2 | Several Continues today. Sure this is worth a window? | Continue anyway |

Never Mind must not raise the level.

## Steps for the agent

1. If the human has not run the checklist yet: stop after this file. Do not “improve” copy.
2. If they report FAIL (still L0 after 2 Continues on one app): inspect `InterventionState.continueCount`, `resolvedAppID`, and whether the shield process can read `TodayEventLog` in the App Group. Fix the read path only. Log `ATTN-V11-00` with continues_today and level.
3. Do not change wall length, unique end minutes, or usage threshold.
4. Record PASS/FAIL in `Journal-Context/PRODUCTION_PROGRESS.md`.

## Agent exit checks

- [x] No closer edits
- [x] Code change only if device FAIL (none needed)
- [x] Result written down from the human, not from this file

## Physical-device checklist (human)

Use **one** tracked app. Wait for the wall between Continues so you see a fresh shield.

- [x] First open today → L0 (“Pause a beat”)
- [x] Continue once → use / get yanked → next shield is **L1** (“already today”)
- [x] Continue again (still 2 today) → still **L1**
- [x] Third Continue → next shield is **L2** (“Several Continues” / “Continue anyway”)
- [x] Never Mind on another app (or same after reset) does **not** raise that app’s Continue level
- [x] Force-quit Attention → open the same shielded app → level still matches Continues today

## Definition of done

- [x] Human confirmed 2026-09-30 on TestFlight 0.1 (3). **PASS.** No code change.

Note: "Reset today's Continue / Never Mind counts" on Apps no longer returns a shield to L0, because the level also counts today's logged Continue events. Test on a fresh day instead.

**Next:** [V11-01 — Never Mind win](./MILESTONE_01_NEVER_MIND_WIN.md)
