# iOS Production Progress

Living notes for agents building **Attention v1** (production milestones).

Canonical design: `../ATTENTION_V1_DESIGN_PLAN.md`  
Milestones: `../milestones-production/`  
Results: `../docs/PRODUCTION_RESULTS.md`

Last updated: 2026-09-19

---

## Where we are

| Item | Value |
|---|---|
| Current milestone | **P04 — Access Windows** |
| Status | **BUILT — awaiting physical-device confirmation** |
| Prior | **P00–P03 PASS** (P03 human 2026-09-19) |

---

## P04 agent notes

- Continue → `AccessWindowBridge.beginWindow`
- Host timer + scene sync; policy locked **`on_window_end` / `unsafe_interrupt=off`**
- Deferred re-shield when Attention background/quit at end
- Duration presets: 15s debug, 1/5/10/15 min (default 15s for easy checks)
- Honest unit: `access_window` only
- Tag: `ATTN-P04`

---

## Next action

Human P04 device checklist. After PASS → P05.
