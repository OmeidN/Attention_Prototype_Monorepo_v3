AGENTS DO NOT MODIFY THIS FILE UNLESS DIRECTLY TOLD BY HUMAN

# Wall reshield trials — 2026-09-22 (wall_multi_v7)

Device screenshots + host logs from Attention. Closer is wall-only: `wall = max(60, window)`, minute-aligned. 15s debug and 1 min both arm a **~60s** wall (often 1–2 min after snap). `code=wall_multi_v7` / `monitor_code=wall_multi_v7` confirmed on device.

Prior bug (v6): first `intervalDidEnd` could wipe the next Continue’s pending row, so the second wall never closed. v7: unique end minutes, live-marker fail-closed, coordinated pending-map CAS, host catch-up if DeviceActivity drops a callback.

## Trial 1 — both apps 15s debug (Attention open)

Human splits (video clock):

| Split | Time | App |
| --- | --- | --- |
| 1 | 00:01:18 | Snap |
| 2 | 00:02:20 | IG |
| 3 | 00:03:33 | Snap |
| 4 | 00:04:18 | IG |
| 5 | 00:05:18 | Snap |
| 6 | 00:06:19 | IG |
| 7 | 00:06:53 | stopped, Clear shields |

Host log (UTC): Continue IG 02:10:47, Snap 02:12:05, IG 02:13:05, Snap 02:14:19, IG 02:15:07, Snap 02:16:06, IG 02:17:05. Clear 02:17:59.

Screenshot mechanism mix:

- IG closes were `last_close=wall_clock` at the armed minute + ~2s (02:13:02, 02:15:02, 02:17:02).
- Snap sometimes `wall_clock` (02:12:02, 02:16:02) and sometimes `wall_catchup_host_app_scene_active` (02:13:55, 02:17:49) when Attention was foregrounded near the armed end.
- After each Continue, `pending=[Instagram,Snapchat]` and ends were **different minutes** (02:13 / 02:14 / 02:15 / 02:16 / 02:17 / 02:18 / 02:19). The v6 wipe (`remaining=0` on a fresh session) did not repeat.

Why this trial felt off: 15s debug is not a 15s door — it is a 60s wall. The ~61s cadence is the product mapping. Opening Apps also let host catch-up close Snap a few seconds early (20s due slack). That is fallback, not a missed shield.

## Trial 2 — IG 3 min, Snap 1 min (Attention open, no host log)

| Split | Time | App |
| --- | --- | --- |
| 1 | 00:01:23 | Snap |
| 2 | 00:03:21 | IG |
| 3 | 00:04:18 | Snap |
| 4 | 00:05:20 | Snap |
| 5 | 00:07:23 | IG |
| 6 | 00:08:10 | Snap |

Cadence matches windows (~1 min Snap, ~3 min IG). Screenshots still show unique ends and pending both apps. Snap again mixed `wall_clock` and `wall_catchup_host_*`; IG stayed `wall_clock`.

## Trial 3 — Attention force-quit, IG 3 min, Snap 1 min

No screenshots / no host log. Extension-only path.

| Split | Time | App |
| --- | --- | --- |
| 1 | 00:01:24 | Snap |
| 2 | 00:03:24 | IG |
| 3 | 00:04:23 | Snap |
| 4 | 00:06:24 | Snap |
| 5 | 00:07:23 | IG |
| 6 | 00:08:23 | Snap |
| 7 | 00:10:24 | Snap |
| 8 | 00:11:24 | IG |
| 9 | 00:12:24 | Snap |
| 10 | 00:14:23 | Snap |
| 11 | 00:15:23 | IG |
| 12 | 00:15:33 | stopped — human: seems consistent |

~1 min Snap / ~3 min IG across 15 minutes with the host dead. This is the production closer.

## Trial 4 — Attention force-quit, Snap 1 / IG 3 / TikTok 5

No screenshots / no host log. Splits 16–18: no Continue. Split 19: Continue all three at once, then record the next closes.

| Split | Time | App | Note |
| --- | --- | --- | --- |
| 1 | 00:01:17 | Snap | |
| 2 | 00:03:17 | IG | |
| 3 | 00:04:19 | Snap | |
| 4 | 00:05:18 | TikTok | |
| 5 | 00:06:18 | Snap | |
| 6 | 00:07:16 | IG | |
| 7 | 00:08:19 | Snap | |
| 8 | 00:10:19 | Snap | |
| 9 | 00:11:19 | TikTok | |
| 10 | 00:12:19 | IG | |
| 11 | 00:13:19 | Snap | |
| 12 | 00:15:17 | Snap | |
| 13 | 00:16:19 | IG | |
| 14 | 00:17:22 | TikTok | |
| 15 | 00:18:19 | Snap | |
| 16 | 00:20:18 | IG | no Continue |
| 17 | 00:21:19 | Snap | no Continue |
| 18 | 00:23:15 | TikTok | no Continue |
| 19 | 00:23:28 | Continue all | |
| 20 | 00:25:19 | Snap | ~2 min after continue-all (1 min + snap) |
| 21 | 00:27:18 | IG | ~4 min (3 min + snap) |
| 22 | 00:29:19 | TikTok | ~6 min (5 min + snap) |

Per-app walls stayed independent. Leftover walls still fired after Continues stopped. After continue-all, close order was Snap → IG → TikTok, matching window length.

## Trial 5 — Attention force-quit, all three on 1 min

No screenshots / no host log. Leftover walls from the prior arm (splits 1–3, no Continue), then Continue all at 00:04:01, then Continue each app again as it closed.

| Split | Time | App | Note |
| --- | --- | --- | --- |
| 1 | 00:01:48 | Snap | no Continue (leftover) |
| 2 | 00:02:48 | IG | no Continue (leftover) |
| 3 | 00:03:49 | TikTok | no Continue (leftover) |
| 4 | 00:04:01 | Continue all | few seconds apart |
| 5 | 00:05:48 | Snap | Continue |
| 6 | 00:06:45 | IG | Continue |
| 7 | 00:07:45 | TikTok | Continue |
| 8 | 00:08:47 | Snap | Continue |
| 9 | 00:09:47 | IG | Continue |
| 10 | 00:10:51 | TikTok | Continue |

Human expected closes a few seconds apart (same 1 min window, Continues a few seconds apart). Observed ~1 min between apps (Snap → IG → TikTok), then the same 1 min stagger on the next cycle. Walls did close, and Continue after each close still got a new wall (no v6 wipe).

Cause: v7 `uniquedEndDate` plus DeviceActivity’s hour:minute-only schedule. Three 1 min Continues in the same minute snap to the same end slot; uniquing bumps the second and third apps by +1 and +2 minutes so `repeats: false` does not drop a sibling `intervalDidEnd`. That stagger is what the splits show.

## Trial 6 — REJECTED: `wall_burst_v1` (branch `test/wall-burst-close`, deleted)

Dropped unique end minutes. First due `intervalDidEnd` was supposed to reshield every pending app Continued within ~30s.

Human: Continue Snap, then IG, then TikTok within ~1s. Snap shielded ~1:32, TikTok ~1:35. **Instagram never shielded.** Later ~3:14 Snap+TikTok closed together; IG still open.

Restore: `git checkout main` → `98291b0`. Burst branch deleted.

## Read

- **Current closer:** `wall_multi_v7` on `main` @ 98291b0.
- v7 did not repeat the “first close kills the next wall” failure.
- Force-quit trials (3, 4, 5) are the clean proof the monitor extension can close without Attention.
- Trial 1 noise is the 15s→60s floor plus host catch-up while Apps was in the foreground, not a second-wall wipe.
- Snap’s `intervalDidEnd` is the flakier of the two when Attention is open; host catch-up covers it. When Attention is quit, Snap still closed on the 1 min cadence.
- Trial 5: same-length walls continued together do **not** close together. They queue one minute apart by design (unique end minutes).
- Trial 6: burst-close is **not** a substitute for unique end minutes. A dropped sibling stays unshielded.
