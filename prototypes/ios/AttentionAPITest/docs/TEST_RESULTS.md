# iOS Test Results

## Environment

- Mac: Apple silicon (M4), local
- macOS: 26.6.2 (25G83)
- Xcode: 26.6 (17F113)
- iOS SDK: 26.5
- iPhone model: iPhone 17
- iOS: 26.6.1
- Build installation method: Xcode → USB → physical iPhone
- Apple Developer status: paid Apple Developer Program membership
- Team ID: VPG6W79282
- Bundle id: com.attention.apitest
- Entitlements file: AttentionAPITest/AttentionAPITest.entitlements (`com.apple.developer.family-controls` + App Groups)
- App Group: group.com.attention.apitest
- Family Controls signing status: VERIFIED on device — individual authorization `approved` (2026-09-06)


| Milestone | Test                    | Result     | Evidence / Notes                                                                                                                                                     |
| --------- | ----------------------- | ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| M00       | Environment             | PASS       | Physical iPhone 17 / iOS 26.6.1 via Xcode USB. Setup shows correct device/OS/bundle `com.attention.apitest`. ISO timestamp updates on leave/return. Human confirmed 2026-09-06. |
| M01       | Base project            | PASS       | Setup/Experiments/Logs on device. Test log lines persist across leave/return and relaunch until Clear; Clear empties; Copy works. Human confirmed 2026-09-06. |
| M02       | Authorization           | PASS       | Cold launch `notDetermined` → Request individual → `request_success status=approved`. Human confirmed 2026-09-06 on iPhone 17. |
| M03       | App selection           | PASS       | UUID PK + naming + App Group. Name probe NO. Follow-ups confirmed 2026-09-06: one-at-a-time add (stable UUIDs); uncheck-tracked rejected; remove one / multi-remove / Clear all. |
| M04       | Shield reliability      | PASS       | `shield_apply count=2 labels=[Gram, Tok]`. Apple default “restricted” shield on tracked apps; Clear shield restores launch. Untracked apps open normally. Survives Attention force-quit and **reboot**. No leaks reported. Human confirmed 2026-09-06. |
| M05       | Custom shield           | PASS       | FULL: title `Attention — Gram`, subtitle flips A↔B via App Group (`shared OK`), buttons Never Mind / Continue, hourglass icon. No rebuild needed for variant change. Screenshots 2026-09-06. |
| M06       | Shield actions          | PASS       | Never Mind keeps block; Continue clears that app’s token + `.close` (backs out; **extra tap** to open — no auto-launch API). Works with Attention force-quit/closed — `host_app_needed=no`. App Group: `continue label=Gram id=74C0B594-…`. Host-seen latency ≈9.85s = Attention reopen delay. After Continue, stays unshielded until manual Shield (M10). Human confirmed 2026-09-06. |
| M07       | Usage threshold         | PASS       | `threshold_unit=duration` (DateComponents; not opens). All-day monitor; per-app 1‑min events. Device: `intervalDidStart` + `eventDidReachThreshold` for Gram/Tok; once-per-event-per-interval (no re-fire on reopen same day until Restart). Untracked/idle did not falsely fire. Human confirmed 2026-09-08. |
| M08       | Open detection          | PASS       | Verdict **`not opens`**. Report embed renders (`duration=0m0s pickups=0`) but **host cannot** read that number: Report API display-only; App Group side-channel never wrote (`attempted=false`); host `DeviceActivityData.activityData` fails (`UsageTrackingAgent` sandbox 159 / hang). Trial: Home×20 + Recents×10 Truth taps; **0** new `eventDidReachThreshold` (`monitoring=false`; last threshold still 2026-09-08). Home vs Recents indistinguishable. Human confirmed 2026-09-09. |
| M09       | Session/access fallback | PASS       | Honest unit **`access_window`** (not session; usage_time optional checkpoint only). Continue starts window; stay past end → no mid-use yank; leave/return inside window → still unshielded; after end + Attention active → `host_deferred_on_attention_active` reshield. Seen: `window_end_while_foreground deferred=true` (15s + 60s); `usage_checkpoint` for Gram after window. Human confirmed 2026-09-14. |
| M10       | Re-shielding            | PASS       | Modes measured. **`on_window_end`** (unsafe off): timer + deferred reshield OK; no mid-use yank. **`on_threshold`**: shield returned mid-use after ~1 min (extension path; harsher). **`manual_only`**: manual button works. Production-acceptable: **`on_window_end`**. Human confirmed 2026-09-16. |
| M11       | Dynamic intervention    | PASS       | L0→L1→L2 visible on shield (`shared OK`). Continues bump levels; Never Mind does not. Force-quit host → still L2. L2 Continue delay unavailable (API). Trust: **trustworthy** (copy/levels). Human confirmed 2026-09-16. |
| M12       | Stress tests            | PASS       | Force-quit, reboot, lock/unlock, rapid reopen, app switcher, airplane, date rollover, revoke auth: as expected. **Full-day: SKIPPED.** #6 notifications: shielded app suppresses notifs; after Continue backlog appears; re-shield clears NC entries (no tap). Human confirmed 2026-09-17. |
| M13       | Final verdict           | AWAITING HUMAN | Draft: **Access Window Model** — see `docs/ARCHITECTURE_DECISION.md`. |




## API facts read from the SDK (iPhoneOS26.5.sdk)

Recorded from `.swiftinterface` files before device testing. Device behavior still has to confirm each one.

- `threshold_unit`: **duration** (M07 + M08). No N-opens API; device trial confirms thresholds do not track launches.
- `report_host_readable`: **false on device (M08)** — host cannot read a numeric count out of `DeviceActivityReport`; only the sandboxed SwiftUI embed shows a number. App Group side-channel from report extension did not reach host. Host `DeviceActivityData.activityData` sandboxed/hung. Pickups are **not** opens (`not opens` verdict).
- `token_name_readable`: **NO on this device (M03)** — `FamilyActivityData.shared.installedApplications` threw "Couldn't communicate with a helper application."; `Application(token:).localizedDisplayName` also empty. User-typed labels remain the only reliable naming path. Revisit only if a later OS build changes behavior.
- `token_refresh_api`: `ManagedSettings.Token.refresh(_:)` exists on iOS 26.5+. Picker re-bind remains the fallback; M03 exercised picker re-bind successfully on device.
- `family_activity_picker_lock`: **NO API** — cannot disable unchecking specific apps in the system picker. App rejects add if tracked tokens were unchecked; remove is in-app only.
- `managed_settings_shield_manual`: **YES on this device (M04)** — `ManagedSettingsStore.shield.applications` blocks tracked apps with Apple’s default shield; clear works; persists across Attention quit and device reboot.
- `honest_unit_fallback`: **`access_window` (M09)** — Continue-triggered timed unblock; host timer / deferred re-shield when Attention active. Do not call timer expiry `session_end`. `usage_time` = optional M07 checkpoint only; `session` not validated.
- `reshield_production_mode`: **`on_window_end` (M10)** — preferred. `on_threshold` can yank mid-use; `manual_only` requires host. `unsafe_interrupt` stays off for production candidate.
- `friction_levels_shared_state`: **trustworthy (M11)** — ShieldConfiguration reads continues_today from App Group; L0/L1/L2 copy adapts; survives host force-quit. No API to delay Continue button.
