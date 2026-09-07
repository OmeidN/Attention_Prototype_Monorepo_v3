import Foundation
import Combine
import DeviceActivity
import ManagedSettings

/// Host-side DeviceActivityCenter start/stop for M07.
@MainActor
final class DeviceActivityMonitoring: ObservableObject {
    static let shared = DeviceActivityMonitoring()

    private let center = DeviceActivityCenter()
    private let activityName = DeviceActivityName(DeviceActivityBridge.activityNameRaw)

    /// Probe threshold shown on screen (duration minutes).
    let thresholdMinutes = 1

    @Published private(set) var lastError: String?
    @Published private(set) var isMonitoring = false

    private init() {
        DeviceActivityBridge.writeThresholdClaim()
        isMonitoring = DeviceActivityBridge.suite?.bool(forKey: DeviceActivityBridge.monitoringActiveKey) == true
    }

    func refreshFromStore() {
        isMonitoring = DeviceActivityBridge.suite?.bool(forKey: DeviceActivityBridge.monitoringActiveKey) == true
    }

    func start(apps: [TrackedApp]) {
        lastError = nil
        guard !apps.isEmpty else {
            lastError = "No tracked apps — add apps in Experiments first."
            TestLogger.shared.log("ATTN-M07", "monitor_start_failed reason=no_apps")
            return
        }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )

        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for app in apps {
            let name = DeviceActivityEvent.Name(app.id.uuidString)
            events[name] = DeviceActivityEvent(
                applications: [app.token],
                threshold: DateComponents(minute: thresholdMinutes)
            )
        }

        do {
            try center.startMonitoring(activityName, during: schedule, events: events)
            DeviceActivityBridge.markMonitoringStarted(
                ids: apps.map(\.id.uuidString),
                labels: apps.map(\.userLabel),
                thresholdMinutes: thresholdMinutes
            )
            isMonitoring = true
            let labels = apps.map(\.userLabel).joined(separator: ",")
            TestLogger.shared.log(
                "ATTN-M07",
                "monitor_started activity=\(DeviceActivityBridge.activityNameRaw) threshold_minutes=\(thresholdMinutes) apps=\(apps.count) labels=[\(labels)] threshold_unit=duration"
            )
        } catch {
            lastError = String(describing: error)
            isMonitoring = false
            TestLogger.shared.log("ATTN-M07", "monitor_start_failed error=\(error)")
        }
    }

    func stop() {
        lastError = nil
        center.stopMonitoring([activityName])
        DeviceActivityBridge.markMonitoringStopped()
        isMonitoring = false
        TestLogger.shared.log("ATTN-M07", "monitor_stopped activity=\(DeviceActivityBridge.activityNameRaw)")
    }
}
