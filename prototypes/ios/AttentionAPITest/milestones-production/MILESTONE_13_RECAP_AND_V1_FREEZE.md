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

- [x] Build succeeds
- [x] Recap uses event store only
- [x] `V1_SCOPE_FREEZE.md` exists
- [x] Grep product UI for dishonest “open” metrics → clean

## Physical-device checklist (human)

- [x] Recap matches lived day (Never Minds / Continues / windows) — 2026-09-25
- [x] Affirm or reject each of the 6 success criteria in `PRODUCTION_RESULTS.md` — 2026-09-25
- [x] Known limitations list matches reality
- [x] Agree v1 scope is frozen — 2026-09-26

## Definition of done

- [x] Thin recap on device
- [x] Scope freeze doc accepted by human
- [x] Production milestone track complete for v1

**Next:** [`../milestones-v1.1/milestones-v1.1.md`](../milestones-v1.1/milestones-v1.1.md)
