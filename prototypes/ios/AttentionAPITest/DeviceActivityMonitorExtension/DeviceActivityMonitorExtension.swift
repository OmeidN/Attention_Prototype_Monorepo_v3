import DeviceActivity
import Foundation
import ManagedSettings

/// Wall-clock interval end (P05B) hard re-shield without Attention host. Usage threshold closer is off.
/// Supports per-app wall activity names (`attention.p05b.wall.<uuid>`).
final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        DeviceActivityBridge.recordIntervalStart(activity: activity.rawValue)
        if HardWindowMonitor.isWallActivity(activity.rawValue) {
            HardWindowMonitor.suite?.set(
                "wall_interval_started activity=\(activity.rawValue) at=\(ISO8601DateFormatter().string(from: Date()))",
                forKey: HardWindowMonitor.wallArmSummaryKey
            )
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        DeviceActivityBridge.recordIntervalEnd(activity: activity.rawValue)

        if HardWindowMonitor.isWallActivity(activity.rawValue) {
            HardWindowMonitor.suite?.set(
                "wall_interval_ended activity=\(activity.rawValue) at=\(ISO8601DateFormatter().string(from: Date()))",
                forKey: HardWindowMonitor.wallArmSummaryKey
            )
            let applied = ReshieldPolicy.tryWallReshieldFromMonitorExtension(activityRaw: activity.rawValue)
            if !applied {
                HardWindowMonitor.suite?.set(
                    "wall_interval_end pending_reshield_failed activity=\(activity.rawValue) at=\(ISO8601DateFormatter().string(from: Date()))",
                    forKey: HardWindowMonitor.wallArmSummaryKey
                )
            }
        }
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
        DeviceActivityBridge.recordThreshold(activity: activity.rawValue, eventRaw: event.rawValue)

        let (ids, labels) = Self.resolveEvent(event.rawValue)
        let applied = ReshieldPolicy.tryReshieldFromMonitorExtension(
            eventRaw: event.rawValue,
            ids: ids,
            labels: labels
        )
        if ReshieldPolicy.mode() == .onThreshold {
            if !applied {
                let decision = HardWindowMonitor.suite?.string(forKey: HardWindowMonitor.lastUsageThresholdDecisionKey) ?? ""
                if decision == "premature" {
                    let rearmNote = HardWindowMonitor.rearmAfterPrematureIgnore()
                    HardWindowMonitor.suite?.set(
                        "usage_threshold_skipped_premature event=\(event.rawValue) \(rearmNote)",
                        forKey: "attention.p05a.last_hard_reshield_note"
                    )
                } else {
                    ReshieldPolicy.markPendingThreshold(eventRaw: event.rawValue, labels: labels)
                }
            }
        }
    }

    private static func resolveEvent(_ eventRaw: String) -> (ids: [String], labels: [String]) {
        guard let data = ReshieldPolicy.suite?.data(forKey: ShieldCopySettings.trackedAppsKey),
              let apps = try? JSONDecoder().decode([TrackedApp].self, from: data)
        else { return ([eventRaw], []) }

        if let uuid = UUID(uuidString: eventRaw),
           let app = apps.first(where: { $0.id == uuid }) {
            return ([app.id.uuidString], [app.userLabel])
        }
        return ([eventRaw], [])
    }
}
