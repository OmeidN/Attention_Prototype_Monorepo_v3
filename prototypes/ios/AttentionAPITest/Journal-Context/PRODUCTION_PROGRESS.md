# iOS Production Progress

Living notes for agents building **Attention v1** (production milestones).

Canonical design: `../ATTENTION_V1_DESIGN_PLAN.md`  
Milestones: `../milestones-production/`  
Results: `../docs/PRODUCTION_RESULTS.md`  
Lab (read-only evidence): `../milestones-testing/`, `../docs/TEST_RESULTS.md`

Last updated: 2026-09-18

---

## Where we are

| Item | Value |
|---|---|
| Current milestone | **P01 — Tracked Apps** |
| Status | **BUILT — awaiting physical-device confirmation** |
| Prior | **P00 PASS** (human 2026-09-18) |
| Architecture | Access Window Model (from lab) |
| Boundary | evolved lab project — `com.attention.apitest` / `group.com.attention.apitest` |
| Primary UI | Shell tab + **Apps** tab (`ProductTrackedAppsView`) |

---

## P01 agent notes

- Reuses `TrackedAppsStore` / `NamingAppsView` (UUID PK in App Group).
- Product UI: add one → name → list; remove / multi-remove / clear; reject unchecked tracked; Re-bind + `ManagedSettingsStore.refresh` attempt.
- Tag: `ATTN-P01`. No shields (P02).
- Do **not** mark PASS until human confirms on device.

---

## Rules

1. One milestone at a time; stop for physical-device confirmation.
2. Never mark PASS without human on-device confirmation.
3. Honest metrics only (`access_window`, intentional choice, Continue).
4. Default re-shield: `on_window_end`, unsafe off.
5. No backend / StoreKit / AI / Android unless explicitly asked.

---

## Next action

Human runs P01 physical-device checklist. After PASS → P02.
