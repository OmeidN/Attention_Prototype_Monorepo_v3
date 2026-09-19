# P09 — Onboarding

**Goal:** first-run onboarding that teaches the real loop and is honest about notification side effects before the user commits apps.

**User-visible change:** cold install → stepped onboarding → ends with shields applied (or explicit skip with warning). Returning users skip to Home.

**Prerequisite:** P01–P08 features exist (auth, pick/name, shield loop, windows, home, settings).

**Agent rule:** implement this milestone only. No 7-day mandatory baseline gate unless human insists — design plan allows day-one intervention with conservative goals. No accounts.

## Out of scope

- Usage checkpoint feature → **P10**
- Dogfood matrix → **P11**
- App Store / TestFlight → **P12**

## Context

Lab M12: shielded apps suppress notifications; backlog may appear after Continue; re-shield can clear NC entries. Onboarding must say this plainly.

## Steps for the agent

1. First-launch flag. Steps (adjust copy, keep intent):
   1. Why Attention (pause → choose → reinforce)
   2. Family Controls authorization
   3. Pick apps + name them (reuse P01)
   4. **Notification honesty** — quieter/delayed/cleared alerts while shielded; don’t shield critical-alert apps
   5. Default window length + Continue budget (reuse P08 defaults)
   6. Apply shields + land on Home
2. Require acknowledgment checkbox or explicit Continue on the notification screen.
3. Re-entry: Settings → “Show onboarding tips” optional.
4. Tag `ATTN-P09`. Instrument step completions with timestamps.

## Agent exit checks

- [ ] Build succeeds
- [ ] First-launch gate works; second launch skips
- [ ] Notification honesty step cannot be skipped without acknowledgment
- [ ] No claim of tracking opens in onboarding copy

## Physical-device checklist (human)

- [ ] Delete app / reset first-launch → full onboarding appears
- [ ] Auth + pick + name + notify honesty + shield apply succeed
- [ ] Second launch → Home directly
- [ ] Copy feels accurate vs real shield/notification behavior
- [ ] Record in `PRODUCTION_RESULTS.md`

## Definition of done

- [ ] Onboarding complete path on device
- [ ] Human confirmed honesty screen is clear

**Next:** [P10 — Usage Checkpoint (Optional)](./MILESTONE_10_USAGE_CHECKPOINT_OPTIONAL.md)
