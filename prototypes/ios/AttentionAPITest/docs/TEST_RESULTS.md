# iOS Test Results

## Environment

- Mac: Apple silicon (M2), local
- macOS: 26.6.2 (25G83)
- Xcode: 26.6 (17F113)
- iOS SDK: 26.5
- iPhone model: NOT RECORDED
- iOS: NOT RECORDED
- Build installation method: Xcode → USB → physical iPhone
- Apple Developer status: paid Apple Developer Program membership
- Team ID: NOT RECORDED
- Bundle id: com.attention.apitest
- App Group: group.com.attention.apitest (from M03)
- Family Controls signing status: NOT VERIFIED

| Milestone | Test | Result | Evidence / Notes |
|---|---|---|---|
| M00 | Environment | BUILDS — AWAITING DEVICE | Hand-authored project builds for `generic/platform=iOS`, SDK 26.5, MinimumOSVersion 17.0. No signing yet. |
| M01 | Base project | BUILDS — AWAITING DEVICE | Setup/Experiments/Logs tabs, TestLogger (500-line persisted ring buffer), ExperimentStore. Grep for FamilyControls/ManagedSettings/DeviceActivity returns zero hits. |
| M02 | Authorization | NOT TESTED | |
| M03 | App selection | NOT TESTED | |
| M04 | Shield reliability | NOT TESTED | |
| M05 | Custom shield | NOT TESTED | |
| M06 | Shield actions | NOT TESTED | |
| M07 | Usage threshold | NOT TESTED | |
| M08 | Open detection | NOT TESTED | |
| M09 | Session/access fallback | NOT TESTED | |
| M10 | Re-shielding | NOT TESTED | |
| M11 | Dynamic intervention | NOT TESTED | |
| M12 | Stress tests | NOT TESTED | |

## API facts read from the SDK (iPhoneOS26.5.sdk)

Recorded from `.swiftinterface` files before device testing. Device behavior still has to confirm each one.

- `threshold_unit`: **duration**. `DeviceActivityEvent.threshold` is `Foundation.DateComponents`; neither initializer accepts an occurrence count. "Opened N times" is not expressible through DeviceActivity events. Confirm on device in M07.
- `report_host_readable`: UNKNOWN — `DeviceActivityData.ApplicationActivity` exposes `numberOfPickups: Int` and `totalActivityDuration`, but only inside the sandboxed report extension. Whether that number can reach the host process is M08's experiment.
- `token_name_readable`: UNKNOWN — `FamilyActivityData.shared.installedApplications` (iOS 26.4+) returns `Application` values carrying `bundleIdentifier` and `localizedDisplayName`. M03 probes whether this resolves on the test device.
- `token_refresh_api`: `ManagedSettings.Token.refresh(_:)` exists on iOS 26.5+. Picker re-bind remains the fallback.
