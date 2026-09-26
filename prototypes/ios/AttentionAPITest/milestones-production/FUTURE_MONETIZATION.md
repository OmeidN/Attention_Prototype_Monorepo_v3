# Future Monetization Context (Post–v1)

**Status:** Product / business context for future agents — **not a production milestone**.  
**Do not implement** during P00–P13. v1 remains: no backend, accounts, StoreKit, analytics SDKs, or AI (`milestones-production.md` rule 7).

**Audience:** Future agents scoping Pro, Family, Commitment Credits, or paywalls.  
**Related:** [`../ATTENTION_V1_DESIGN_PLAN.md`](../ATTENTION_V1_DESIGN_PLAN.md), [`../docs/SCORING_WEIGHTS.md`](../docs/SCORING_WEIGHTS.md), [`milestones-production.md`](./milestones-production.md).

---

## Agent rules when using this file

1. This document is **direction**, not an implementation ticket. Do not start StoreKit, wallets, or family sync unless the human explicitly asks for that work.
2. Keep **honest metrics**: Continues, Never Minds (`intentional_choice`), `access_window` / window minutes — never claim opens/sessions.
3. **Personal product first**, then Family and stakes as add-ons on the same event model.
4. Prefer **subscription as primary revenue**; credits/stakes are optional secondary.
5. Privacy-local defaults remain the personal-mode baseline; Family sharing is explicit opt-in.

---

## Product reminder (what we monetize)

Attention’s core loop:

```text
Shield → Never Mind OR timed Continue → re-shield → reinforce (goals / XP / streak)
```

Primary behavior unit = **access window** (not opens).  
Positioning: fitness tracker for attention — intentionality over abstinence.

---

## Recommended monetization stack

| Layer | Role | When |
|---|---|---|
| **Free** | Acquisition / habit formation — core shield loop | Ship with / right after v1 spine |
| **Pro (subscription)** | Main recurring revenue | After v1 freeze + distribution path |
| **Family (higher ARPU)** | Parent visibility + household SKU | After personal Pro works |
| **Commitment Credits (optional)** | Behavioral “skin in the game”; secondary revenue | After backend exists; App Review risk |

**Do not lead** with ads (trust / Screen Time conflict) or with stakes-as-only-business (Apple risk + lumpy revenue).

### Suggested pricing shape (indicative, not locked)

| Plan | Role |
|---|---|
| Free | Prove the pause works |
| Pro monthly (~$5–9) | Impulse convert after week 1 |
| Pro yearly (~$40–60, ~40% off) | Main revenue |
| Family (higher than Pro) | 1 parent + N kids; StoreKit Family Sharing eligible |
| Lifetime | Rare / early adopters only — do not lead |

Conversion triggers (in-product): free tracked-app limit; want programs; end of free history window; strong weekly recap; soft 7–14 day Pro trial after onboarding or first good week.

**Do not** hard-lock Continue or shields behind pay — fights “intentionality over abstinence.”

---

## Free vs Pro gating

### Free forever (habit engine)

- Shield on a **small** number of apps (e.g. 1–3)
- Never Mind / Continue + access windows
- Basic Today stats, simple daily goals, short streak
- Local-only data; honest metrics

### Pro (subscription)

Gate layers that deepen outcomes after the loop is trusted:

1. **Programs** — 7 / 14 / 21 / 30-day content packs (“Reflexive Check Detox,” “Evening Scroll Down,” etc.)
2. **Weekly Attention Plan** — rules-based first (patterns from Continues / windows / time-of-day); AI later
3. **Long-term history + trends** — Free: ~7 days; Pro: 90 days / forever
4. **Richer recaps** — Free: thin summary; Pro: narrative weekly review
5. **Advanced friction** — more presets, per-app budgets, firmer tones; careful not to feel punitive
6. **More tracked apps** — Free: 2–3; Pro: unlimited or high cap
7. **AI Coach (later / Pro+)** — structured insights only; raw logs should not leave device by default

### Opinionated package (locked direction unless human revises)

- **Attention Free** — up to ~3 apps, basic loop, ~7-day Today  
- **Attention Pro** — unlimited apps, programs, weekly plan, full history, advanced budgets, rich recaps  
- **Attention Family** — Pro-class features + child links + parent dashboard  
- **Later: Pro Coach** — privacy-preserving AI on top of Pro  

Aligns with vision stack: Measurement → Behavior Change → Intelligence.

---

## Hosting, backend, auth (implications)

### v1 / current architecture

- **Not server-hosted.** Native iOS app on device + App Store / TestFlight.
- Data: App Group + local event/score store.
- “Auth” in milestones = **Family Controls / Screen Time authorization**, not user login.
- Airplane mode / local loop must keep working for personal core.

### When backend / accounts become required

| Goal | Backend? | User accounts? |
|---|---|---|
| Core shield + Today + goals | No | No |
| Pro via StoreKit alone | Optional | No (Apple receipt on-device) |
| Cross-device sync / restore | Yes or iCloud | Usually yes (Sign in with Apple) |
| **Family parent dashboard** | Yes (or CloudKit family sync) | Yes |
| **Commitment credits / stakes** | **Yes** (server clock + wallet) | Yes |
| Cloud AI coach | Yes | Often yes |

**Direction:** Stay local through v1 → Pro via StoreKit without custom auth → add Sign in with Apple + backend only for Family and/or Credits.

Payments for digital credits/subscriptions **in the iOS app** = **StoreKit** (IAP), not arbitrary Apple Pay / Stripe checkout for digital goods inside the binary.

---

## Family plan

### Intent (human-confirmed)

- **Not** Life360-style live surveillance / location / feed spying.
- **Yes** parent↔child relationship: parent sees the child’s **Attention habit ledger** on the parent’s phone.
- Same app works as **personal self-improvement** and later as **Family**.
- Sequence: **nail single-user first**, then add Family.

### What parents see (honest units only)

- Intentional choices (Never Mind) today / week  
- Continues + budget remaining  
- Access windows taken + total / average window minutes  
- Goals hit / streak (if shared)  
- Weekly recap in choice/window language  

**Do not** promise opens, sessions, or “what they did inside Instagram.”

Marketing wedge vs Apple Screen Time / Qustodio-style limits:

> We don’t spy on the feed. We show how often they paused and chose (Never Mind vs Continue) and how long access windows lasted.

### Product modes

| Mode | Who | Job |
|---|---|---|
| Personal | Adult / teen self | Pause → choose → reinforce; data on-device by default |
| Family | Parent + child | Same loop on child’s device + parent read-only (or light co-pilot) insights |

### Minimal Family add-on (when ready)

1. Child device runs Attention (shield loop unchanged).  
2. Link: Family Sharing / invite / Sign in with Apple family graph.  
3. Sync: child **summary events** → backend or CloudKit → parent device.  
4. Parent UI: Today + Week per child; optional shared goals (e.g. ≤3 Continues on school nights).  
5. StoreKit **Family** subscription (one purchase, household Apple IDs via Apple Family Sharing for subscriptions).

### Explicit Family defaults

- Personal mode: data stays on device.  
- Family mode: explicit opt-in to share **summary events** with linked parents — not raw dumps, not forever by accident.  
- Frame as coaching / co-visibility, not covert monitoring.  
- Acknowledge bypass (other devices, web): friction + visibility, not prison.

### Technical / sequencing notes

- Lab/production to date: **`.individual`** Family Controls only. Guardian/child flows are a **separate lab spike** before building Family UI.
- Child Apple IDs in Family Sharing fail `.individual` auth (see lab M02 notes) — Family product needs Apple’s guardian/child path.
- Distribution + multi-extension entitlements get harder; treat as schedule risk.
- Family is closer to a **second product line** on the Access Window Model than “flip Family Sharing on Pro.”

### Suggested build order for Family

1. Ship individual Attention; prove habit loop.  
2. StoreKit Pro (solo).  
3. Validate demand (waitlist / interviews): parent recap of Never Mind / Continues.  
4. Spike guardian Family Controls on a real child Apple ID.  
5. Then Family dashboard + sync + Family SKU.

### Competitive context (gap, not empty)

| Category | Examples | Notes |
|---|---|---|
| Classic parent dashboards | Qustodio, Bark, Aura, Apple Screen Time | Minutes, blocks, safety — not choice metrics |
| Focus apps + family billing | one sec, Opal | Pause/block for adults; family often = sub sharing or lockdown, not habit ledger |
| Intentionality-for-kids (closest) | Zentime, PapaTime, Unpluq Family | Breathing pause / kid-managed budget / NFC unlock |

**Differentiation:** Access Window Model + parent phone shows the **same honest event log** (Never Mind / Continue / windows), dual personal + Family identity — not message scanning or open-count surveillance.

---

## Commitment Credits & Goal Stakes (optional)

### Positioning

- Optional mode; never required for core loop.  
- Frame: **“skin in the game” / commitment** — not gambling.  
- Copy direction: “You’re more likely to stick when something’s on the line.” Cite research carefully; do not invent “x%” without a source.  
- **No cash-out.** Credits never convert to money. Non-transferable.  

**Avoid:** bet, wager, odds, jackpot, win money.  
**Prefer:** stake, commitment, put credits on the line.

### Realism as monetization

- **Behaviorally** useful for a niche (commitment devices).  
- **Weak as sole business:** users who pass lose $0 ongoing; revenue from fail→top-up, large packs, pack margin.  
- **Apple App Review risk is real:** similar “monetary penalty if you miss goals” models (e.g. Beeminder, HabitBet) have been challenged. Pre-bought credits + fixed forfeit + no cash-out is softer but not safe.  
- **Fallback if rejected:** iOS app tracks goals; purchase/settlement on web (survival pattern used by others).  
- **Requires backend** — not compatible with current local-only v1 rules.

**Direction:** Pro subscription primary; Commitment Credits = optional Pro (or post-Pro) add-on.

### Wallet & purchase

- Sell **consumable IAP** credit packs via StoreKit (e.g. 20 / 50 / 100 / 250).  
- Map packs to use (“50 credits ≈ one month of medium stakes”).  
- Developer margin / Apple cut (15–30%): bake into pack price (opaque platform margin OK; optional transparent “includes platform fee”).  
- Balance **server-side**, mirrored on device; validate Apple receipts before crediting.  
- Handle App Store refunds (claw back credits / void stakes).

### Justify buying more credits (UX-honest)

1. Failed a stake — lost some, want another run.  
2. Bigger / longer stake needs higher cap.  
3. Multiple concurrent goals (later).  
4. Restart after Pause Attention / voided stake.  

**Do not** justify with win-back multipliers or random rewards (gambling feel + Review risk).

### Stake lifecycle

```text
Choose duration → Easy / Medium / Hard or custom → choose stake tier
→ lock N credits in escrow
→ evaluate at end (server clock + event log)
→ Pass: release escrow intact (0 loss)
→ Fail: burn loss amount; return remainder to wallet
```

### Suggested loss schedule (tune later)

Pass = **no credit loss**. Fail burns a fixed amount by tier (remainder returned):

| Stake locked | On fail, burn | Return to wallet |
|---|---|---|
| 5 | 2 | 3 |
| 10 | 3 | 7 |
| 20 | 5 | 15 |
| 50 | 10 | 40 |
| 75 | 15 | 60 |
| 100 | 25–35 (prefer softer than −50) | rest |

Rationale: −50 on 100 is highly punitive and may kill reload willingness / drive 1-star reviews.

### Durations

- Preferred v1 of feature: **7 and 14 days**.  
- Optional later: 3 / 21 / 30.  
- 3-day is noisy; 30-day has high dispute/support cost until reliability is proven.

### Goal presets (tied to Attention metrics)

Use **per-user baseline** (3–7 days of Continues / window minutes / Never Minds) when possible; presets as multipliers of that baseline. Fallback: align with current soft daily goals in `SCORING_WEIGHTS.md` (≤5 Continues/day, ≤15 window min/day, ≥1 Never Mind).

For stake length **D** days (totals over the stake):

| Preset | Continues (total) | Window minutes (total) | Never Minds (total) |
|---|---|---|---|
| **Easy** | ≤ ~`ceil(6.5 × D)` | ≤ ~`ceil(20 × D)` | ≥ `D` |
| **Medium** | ≤ `5 × D` | ≤ `15 × D` | ≥ `ceil(1.5 × D)` |
| **Hard** | ≤ `ceil(3 × D)` | ≤ `ceil(10 × D)` | ≥ `2 × D` |

**Custom knobs (keep few):**

- Max Continues over stake  
- Max access-window minutes over stake  
- Min Never Minds over stake  
- Optional: max Continues per calendar day  
- Duration  

**Evaluation:** all conditions must pass (AND) for clarity in v1 of the feature.

### Guardrails & security (required for stakes)

Local-only stakes are cheatable — **server is authority**.

1. **Server UTC** for stake start/end; timezone snapshot at stake start.  
2. **Event integrity:** upload from App Group/host; reject impossible sequences; prefer App Attest / device-bound identity.  
3. **Date/time tampering:** ignore device clock for evaluation. On significant clock/timezone jump mid-stake: **forfeit loss amount** (or void per disclosed terms).  
4. **Pause Attention / clear shields / revoke Family Controls:** treat as forfeit or partial burn — disclose before lock.  
5. **Uninstall:** wallet + stakes on server; Sign in with Apple restore; missing uploads while uninstalled may fail the plan (disclose).  
6. **One active stake per user** at first.  
7. **Cooldown after fail** (e.g. 24h) — reduces compulsive top-up; looks less gambling-like.  
8. **Caps:** max credits purchasable per month; max stake tier until N successful stakes; **18+** for credit features.  
9. **Measurement honesty:** stake goals use Continue / Never Mind / access_window minutes only.  
10. **Deferred re-shield / host quit:** don’t unfairly fail users for known OS limitations; for staked users prefer reliable closer behavior and/or exclude documented overrun cases — disclose either way.

### Legal / ToS bullets to surface at stake confirm

- Credits have **no cash value**; no cash-out; non-transferable; no refund on fail.  
- Not gambling; optional commitment aid.  
- Not financial advice.  
- Cheating via other devices acknowledged; product is habit aid.

### Cost to developer

| Cost | Handling |
|---|---|
| Apple IAP 15–30% | Pack pricing |
| Backend (auth, wallet, stake engine, receipts) | Required for this feature |
| Support / “unfair fail” tickets | Keep rules simple; 7/14 day stakes first |
| External payment processors in-app | Avoid for digital credits |

---

## Sequencing (do not reorder casually)

```text
P00–P13 v1 spine (local, no StoreKit)
  → Dogfood + Family Controls distribution
  → Pro subscription (StoreKit; free vs Pro gating)
  → Programs / history / rich recaps as Pro value
  → Family spike (guardian auth) → Family SKU + parent dashboard
  → Commitment Credits (optional; backend + Review contingency)
  → AI Coach (privacy-preserving; last)
```

---

## Explicit non-goals (until human asks)

- Implementing any of the above during current production milestones  
- Ads / attention-hostile SDKs as monetization  
- Cash-out, P2P transfers, or randomized credit rewards  
- Parent product that claims open counts or message/content surveillance  
- Replacing Pro subscription entirely with credit packs  

---

## Open decisions (human may revise)

1. Exact Free app cap (2 vs 3) and Pro price points  
2. Family: read-only parent dashboard vs parent-set budgets / approve Continues  
3. Credits: Pro-only vs available to free users  
4. Stake fail burn on 100-credit tier (25–35 vs harsher)  
5. CloudKit vs custom backend for Family sync  
6. Whether Commitment Credits ship in-app or web-settled if Apple rejects  

---

## Changelog

| Date | Note |
|---|---|
| 2026-09-25 | Initial capture from product discussion: Free/Pro, Family habit ledger, Commitment Credits/stakes, hosting, App Review risk, sequencing. |
