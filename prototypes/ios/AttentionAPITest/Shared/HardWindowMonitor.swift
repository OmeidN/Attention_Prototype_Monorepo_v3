import Foundation
import DeviceActivity
import ManagedSettings

/// P05A: arm DeviceActivity usage thresholds so the monitor extension can hard-re-shield
/// without the Attention host. Call `rearm` on every Continue (once-per-interval lab fact).
enum HardWindowMonitor {
    static let activityRaw = "attention.p05a.hard_window"
    static var activityName: DeviceActivityName { DeviceActivityName(activityRaw) }

    static let lastArmAtKey = "attention.p05a.last_arm_at"
    static let lastArmErrorKey = "attention.p05a.last_arm_error"
    static let lastArmSummaryKey = "attention.p05a.last_arm_summary"

    static var suite: UserDefaults? { ShieldCopySettings.suite }

    static func dateComponents(forSeconds seconds: Int) -> DateComponents {
        let clamped = max(15, seconds)
        if clamped % 60 == 0 {
            return DateComponents(minute: clamped / 60)
        }
        if clamped >= 60 {
            return DateComponents(minute: clamped / 60, second: clamped % 60)
        }
        return DateComponents(second: clamped)
    }

    /// Stop + start all-day monitoring with one event per tracked app (threshold = that app's window).
    @discardableResult
    static func rearm(apps: [TrackedApp], reason: String) -> String? {
        let center = DeviceActivityCenter()
        center.stopMonitoring([activityName])

        guard !apps.isEmpty else {
            DeviceActivityBridge.markMonitoringStopped()
            let msg = "rearm_cleared reason=\(reason) apps=0"
            suite?.set(msg, forKey: lastArmSummaryKey)
            suite?.set(ISO8601DateFormatter().string(from: Date()), forKey: lastArmAtKey)
            suite?.removeObject(forKey: lastArmErrorKey)
            return nil
        }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )

        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        var parts: [String] = []
        for app in apps {
            let secs = max(15, app.windowDurationSeconds)
            let name = DeviceActivityEvent.Name(app.id.uuidString)
            events[name] = DeviceActivityEvent(
                applications: [app.token],
                threshold: dateComponents(forSeconds: secs)
            )
            parts.append("\(app.userLabel)=\(secs)s")
        }

        do {
            try center.startMonitoring(activityName, during: schedule, events: events)
            let maxMinutes = apps.map { max(15, $0.windowDurationSeconds) }.max().map { max(1, $0 / 60) } ?? 1
            DeviceActivityBridge.markMonitoringStarted(
                ids: apps.map(\.id.uuidString),
                labels: apps.map(\.userLabel),
                thresholdMinutes: maxMinutes
            )
            let summary = "rearm_ok reason=\(reason) apps=\(apps.count) [\(parts.joined(separator: ","))] unit=usage_duration"
            suite?.set(summary, forKey: lastArmSummaryKey)
            suite?.set(ISO8601DateFormatter().string(from: Date()), forKey: lastArmAtKey)
            suite?.removeObject(forKey: lastArmErrorKey)
            return nil
        } catch {
            let err = String(describing: error)
            suite?.set(err, forKey: lastArmErrorKey)
            suite?.set("rearm_failed reason=\(reason) error=\(err)", forKey: lastArmSummaryKey)
            suite?.set(ISO8601DateFormatter().string(from: Date()), forKey: lastArmAtKey)
            DeviceActivityBridge.markMonitoringStopped()
            return err
        }
    }

    static func statusLine() -> String {
        let summary = suite?.string(forKey: lastArmSummaryKey) ?? "never_armed"
        let at = suite?.string(forKey: lastArmAtKey) ?? "nil"
        let err = suite?.string(forKey: lastArmErrorKey) ?? "none"
        return "\(summary) at=\(at) error=\(err)"
    }
}
