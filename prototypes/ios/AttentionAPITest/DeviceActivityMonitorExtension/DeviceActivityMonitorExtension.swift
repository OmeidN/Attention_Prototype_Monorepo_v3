import DeviceActivity
import Foundation
import ManagedSettings

/// M07: writes interval/threshold callbacks into the App Group for the host to read.
/// M10: optional on_threshold re-shield attempt from this extension.
final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        DeviceActivityBridge.recordIntervalStart(activity: activity.rawValue)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        DeviceActivityBridge.recordIntervalEnd(activity: activity.rawValue)
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
            // Extension cannot write TestLogger; host reads App Group on next active.
            if !applied {
                ReshieldPolicy.markPendingThreshold(eventRaw: event.rawValue, labels: labels)
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
