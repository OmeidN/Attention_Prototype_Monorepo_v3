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
| M07       | Usage threshold         | AWAITING DEVICE | Code restored 2026-09-07: DeviceActivityMonitorExtension + all-day schedule; per-tracked-app events `threshold=1 minute`. Host Start/Stop; App Group callback timestamps. SDK claim: **duration**. Prior partial device evidence (2026-09-06): `intervalDidStart` + `eventDidReachThreshold` fired; finish formal checklist before PASS. |
| M08       | Open detection          | NOT TESTED |                                                                                                                                                                      |
| M09       | Session/access fallback | NOT TESTED |                                                                                                                                                                      |
| M10       | Re-shielding            | NOT TESTED |                                                                                                                                                                      |
| M11       | Dynamic intervention    | NOT TESTED |                                                                                                                                                                      |
| M12       | Stress tests            | NOT TESTED |                                                                                                                                                                      |




## API facts read from the SDK (iPhoneOS26.5.sdk)

Recorded from `.swiftinterface` files before device testing. Device behavior still has to confirm each one.

- `threshold_unit`: **duration**. `DeviceActivityEvent.threshold` is `Foundation.DateComponents`; neither initializer accepts an occurrence count. "Opened N times" is not expressible through DeviceActivity events. Confirm on device in M07.
- `report_host_readable`: UNKNOWN — `DeviceActivityData.ApplicationActivity` exposes `numberOfPickups: Int` and `totalActivityDuration`, but only inside the sandboxed report extension. Whether that number can reach the host process is M08's experiment.
- `token_name_readable`: **NO on this device (M03)** — `FamilyActivityData.shared.installedApplications` threw "Couldn't communicate with a helper application."; `Application(token:).localizedDisplayName` also empty. User-typed labels remain the only reliable naming path. Revisit only if a later OS build changes behavior.
- `token_refresh_api`: `ManagedSettings.Token.refresh(_:)` exists on iOS 26.5+. Picker re-bind remains the fallback; M03 exercised picker re-bind successfully on device.
- `family_activity_picker_lock`: **NO API** — cannot disable unchecking specific apps in the system picker. App rejects add if tracked tokens were unchecked; remove is in-app only.
- `managed_settings_shield_manual`: **YES on this device (M04)** — `ManagedSettingsStore.shield.applications` blocks tracked apps with Apple’s default shield; clear works; persists across Attention quit and device reboot.
