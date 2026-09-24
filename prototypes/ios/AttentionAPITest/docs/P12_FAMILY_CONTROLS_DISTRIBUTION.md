# P12 — Family Controls distribution runbook

Tag: `ATTN-P12`  
Team ID: `VPG6W79282`  
Account Holder only. Development Family Controls already works on device. That is not distribution approval. This runbook does not claim App Store or TestFlight approval.

## Status (2026-09-23)

Requests submitted for all five bundle IDs below. Portal row **Family Controls (Distribution)** shows **Assigned**. Wildcard `*` was not requested. Capabilities checked on the identifiers include Family Controls (Development), Family Controls (Distribution), and Family Controls App and Website Usage. **Assigned is not Approved.** Archive and TestFlight wait.

## Bundle IDs to keep

Do not rename to `com.attention.app` for this request. P00 kept the evolved lab IDs so the paid-team device profile and App Group stay valid. Request distribution on these IDs.

| Target | Bundle ID | Entitlements file | Family Controls | App Group |
| --- | --- | --- | --- | --- |
| Host | `com.attention.apitest` | `AttentionAPITest/AttentionAPITest.entitlements` | yes | `group.com.attention.apitest` |
| Shield Configuration | `com.attention.apitest.ShieldConfiguration` | `ShieldConfigurationExtension/ShieldConfigurationExtension.entitlements` | yes | same |
| Shield Action | `com.attention.apitest.ShieldAction` | `ShieldActionExtension/ShieldActionExtension.entitlements` | yes | same |
| Device Activity Monitor | `com.attention.apitest.DeviceActivityMonitor` | `DeviceActivityMonitorExtension/DeviceActivityMonitorExtension.entitlements` | yes | same |
| Device Activity Report | `com.attention.apitest.DeviceActivityReport` | `DeviceActivityReportExtension/DeviceActivityReportExtension.entitlements` | yes | same |

The Report extension is in the archive. It is not the product metric. It still needs its own distribution request because the target uses Family Controls.

Each entitlements file has `com.apple.developer.family-controls` = true and App Group `group.com.attention.apitest`. Reviewed 2026-09-23. No entitlement edits in P12.

## Submit the requests

1. Sign in at [developer.apple.com](https://developer.apple.com) as the **Account Holder** for team `VPG6W79282`.
2. Open Certificates, Identifiers & Profiles → Identifiers. Confirm each bundle ID above exists.
3. On each identifier, Family Controls and App Groups must be enabled. App Group value: `group.com.attention.apitest`.
4. Submit **Family Controls (Distribution)** for **each** of the five bundle IDs. Development entitlement is not enough for TestFlight or the App Store.
   - From the identifier, use the Family Controls distribution request if the page shows one.
   - Or the Account Holder form: [Family Controls distribution request](https://developer.apple.com/contact/request/family-controls-distribution). If the form takes one bundle ID, submit it five times, once per row in the table.
5. Write the status for each ID in `docs/PRODUCTION_RESULTS.md`: Submitted, Assigned, or Denied. Include the date. Do not mark PASS until those rows are filled from Apple, not from this runbook.

Approvals can lag. Extensions are often slower than the host.

## After Apple approves

1. In Xcode, for each target: Signing & Capabilities → download or regenerate the provisioning profile so it includes Family Controls distribution.
2. Product → Archive (Any iOS Device, Release), scheme `AttentionAPITest`.
3. If the archive fails, copy the **exact** provisioning error into `PRODUCTION_RESULTS.md`. A typical miss is “Provisioning profile doesn't include the Family Controls capability” on one extension.
4. Optional smoke: upload the archive to TestFlight and install on the iPhone. Confirm the shield loop still works. Record that install. This is not App Store approval.

## What this milestone does not do

- No bundle ID rename
- No App Store submission
- No claim that distribution is approved
- No new product features (Settings only shows `Build: TestFlight candidate`)
