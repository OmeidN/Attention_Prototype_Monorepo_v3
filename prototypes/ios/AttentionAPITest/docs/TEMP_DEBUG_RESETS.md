# TEMP DEBUG resets — REMOVE LATER

**Status:** temporary testing affordances added 2026-09-21 (fixed 2026-09-21 evening).  
**Do not ship in v1 freeze.** Delete this file and the UI/API when cleaning up.

## Why

Dogfood / P07 testing piles up Continues, Never Minds, Home events, and XP. Testers need a way to zero state without changing the phone calendar or deleting the app.

## Bug fixed (why wipe looked broken)

First wipe only cleared `attention.p06.events`. The next **ingest** re-imported Continues/Never Minds from `attention.m06.intentional_and_continue_events` (`ShieldActionBridge`), so XP/streak/Never Minds came right back. Access windows stayed ~0 because those are not in that bridge queue.

**Wipe now clears:** P06 log + ShieldActionBridge queue + friction counts + ingest cursors + persisted XP/streak, then recomputes (no resurrect).

## Where (UI)

| Control | Location | What it clears |
|---|---|---|
| **TEMP: Reset counts for this app** | Apps tab → each tracked app row | That app’s friction counts + P06 events + ShieldAction events for that UUID → recompute |
| **TEMP: Wipe ALL Home/XP events** | Apps tab → “TEMP DEBUG resets” | Full wipe as above (all apps) |
| Reset today's Continue / Never Mind counts | Apps → P05 (pre-existing) | Friction counts only (does **not** clear Home/XP) |

## Code to remove later

- `InterventionState.resetCounts(appID:)`
- `TodayEventLog.removeEvents` / `removeAllEvents`
- `ShieldActionBridge.clearAllEvents` / `removeEvents(forAppID:)`
- `TodayStatsStore.tempWipeAllForTesting` / `tempResetAppForTesting`
- `ScoringStore.clearPersistedForTesting`
- Buttons / section marked `TEMP DEBUG` in `ProductTrackedAppsView.swift`
- Log tag `ATTN-TEMP`
- This doc

## Keep

Normal product day rollover (Home filters by calendar day; friction `ensureToday`) stays.
