# P13 — Recap and v1 Freeze

**Goal:** ship a thin **local recap** (end-of-day or weekly) from honest events, then **freeze v1 scope**. Confirm success criteria from the design plan.

**User-visible change:** Recap screen or card: Never Minds, Continues, windows, minutes, goals hit, streak — rules-based copy only. No AI.

**Prerequisite:** P06–P07 metrics; P11 dogfood acceptable.

**Agent rule:** no programs pack, no Pro, no backend, no open counters. After this milestone, new work needs a new milestone list (v1.1+).

## Out of scope

- 7/14/21/30-day programs  
- StoreKit / subscriptions  
- AI coach  
- Android  
- Mid-use yank hard mode (unless already experimental and documented)

## Context

Design plan success criteria — human should be able to affirm:

1. Every tracked app hits a clear pause before entry.  
2. Never Mind feels like a win.  
3. Continue grants a predictable window; door closes without mid-scroll yank.  
4. More Continues → firmer pause copy.  
5. UI never claims opens/sessions you cannot measure.  
6. Notification side effects were understood before committing apps.

## Steps for the agent

1. Recap view: today + last 7 days bars/lists from local store (Charts OK if simple).
2. Rules-based one-liner insights (e.g. “3 Never Minds today”) — no model calls.
3. Copy audit across app: ban open/session claims; prefer access window / intentional choice / Continue.
4. Write `docs/V1_SCOPE_FREEZE.md`: included features, explicit non-goals, known limitations (deferred re-shield, extra tap after Continue, notification suppression, distribution status).
5. Update `Journal-Context/PRODUCTION_PROGRESS.md` → v1 frozen / next backlog.
6. Tag `ATTN-P13`.

## Agent exit checks

- [ ] Build succeeds
- [ ] Recap uses event store only
- [ ] `V1_SCOPE_FREEZE.md` exists
- [ ] Grep product UI for dishonest “open” metrics → clean

## Physical-device checklist (human)

- [ ] Recap matches lived day (Never Minds / Continues / windows)
- [ ] Affirm or reject each of the 6 success criteria in `PRODUCTION_RESULTS.md`
- [ ] Known limitations list matches reality
- [ ] Agree v1 scope is frozen

## Definition of done

- [ ] Thin recap on device
- [ ] Scope freeze doc accepted by human
- [ ] Production milestone track complete for v1

**Next:** stop — or open a v1.1 milestone folder for polish/programs/TestFlight iteration only after freeze.
