# V11-02 — UI pass (existing loop)

**Goal:** make the screens you already live in readable. Same loop, same metrics, less lab-dump. Not a brand system and not new features.

**User-visible change:** Home, Apps, Settings, Recap, and the shield chrome you already have. Drop leftover milestone titles (“P08 — Home + Settings budget”), tighten hierarchy, keep numbers honest.

**Prerequisite:** V11-01 done (Never Mind win copy in place so this pass does not restyle a dead button).

**Agent rule:** implement this milestone only. Prefer clear type, spacing, and section order over new illustrations or custom icons. Do not add StoreKit, programs, or a marketing site. Do not rename the bundle. Home-screen icon can stay the lab pause-bars mark unless a one-file swap is trivial and still ugly-honest.

## Out of scope

- Free / Pro / StoreKit → **not laid out yet** (V11-03+)
- Programs, Family, credits, AI
- Experiments tab / lab probes as product
- Closer, window math, budget lockout
- App Store screenshots / consumer name “Attention”

## What to touch

| Surface | Do | Don’t |
|---|---|---|
| Home | Lead with today + Never Mind win + goals. Metrics still Never Minds / Continues / windows / minutes | New charts that imply opens |
| Shield | Keep L0–L1–L2 + Never Mind win from V11-00/01 | New buttons or delay |
| Apps | Tracked list + names + per-app window. Hide or tuck debug resets | Rebuild picker |
| Settings | Window, budget, Pause, honesty replay. One “lab / debug” disclosure if needed | Paywall |
| Recap | Same store as Home; readable week list | AI copy |
| Dogfood tab | Can stay ugly | Do not delete instrumentation |

## Steps for the agent

1. Inventory product tabs in `RootView` / `Product*View`. List which strings are milestone leftovers vs user-facing.
2. Restyle those five surfaces. One type ramp, consistent list sections, less monospaced dump on Home/Recap.
3. Keep captions that deny opens/sessions.
4. Instrument nothing new except `ATTN-V11-02` on first appear of the revised Home (optional).
5. Stop. Do not start Free/Pro.

## Agent exit checks

- [ ] Build succeeds
- [ ] No StoreKit / new tabs / closer edits
- [ ] Product UI still has no open/session counts
- [ ] Debug resets still reachable (Settings disclosure or Dogfood)

## Physical-device checklist (human)

- [ ] Home is readable without scrolling past lab status first
- [ ] Shield still Never Mind / Continue with correct L-level
- [ ] Settings still changes default window and budget; Pause still confirms
- [ ] Recap totals still match Home for today
- [ ] Dogfood / reset still works if you need it
- [ ] Overlay-install: App Group data still there

## Definition of done

- [ ] Human confirms the loop is the same and the screens are good enough to keep dogfooding

**Next:** stop. V11-03+ (StoreKit / programs) are not written yet.
