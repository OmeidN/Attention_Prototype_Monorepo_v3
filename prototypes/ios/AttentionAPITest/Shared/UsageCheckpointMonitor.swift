import Foundation
import DeviceActivity
import FamilyControls
import ManagedSettings

/// P10: optional duration checkpoint. Side signal only — does not re-shield or gate Continue.
enum UsageCheckpointMonitor {
    static let activityRaw = "attention.p10.usage_checkpoint"
    static var activityName: DeviceActivityName { DeviceActivityName(activityRaw) }

    static let statusKey = "attention.p10.status"
    static let lastErrorKey = "attention.p10.last_error"
    static let lastNoteKey = "attention.p10.last_note"
    static let lastHostLoggedNoteKey = "attention.p10.last_host_logged_note"
    static let lastCheckpointAtKey = "attention.p10.last_checkpoint_at"
    static let thresholdUnitKey = "attention.p10.threshold_unit"
    static let thresholdSeconds = 60

    static var suite: UserDefaults? { ShieldCopySettings.suite }

    static func isCheckpointActivity(_ raw: String) -> Bool {
        raw == activityRaw
    }

    static func statusLine() -> String {
        let status = suite?.string(forKey: statusKey) ?? "off"
        let last = suite?.string(forKey: lastCheckpointAtKey) ?? "none"
        let err = suite?.string(forKey: lastErrorKey) ?? ""
        let unit = suite?.string(forKey: thresholdUnitKey) ?? "duration"
        if err.isEmpty {
            return "status=\(status) unit=\(unit) threshold_s=\(thresholdSeconds) last=\(last)"
        }
        return "status=\(status) unit=\(unit) threshold_s=\(thresholdSeconds) last=\(last) \(err)"
    }

    /// Host only. Restarts this activity. Does not stop wall-clock closers.
    @discardableResult
    static func start(apps: [TrackedApp]) -> String? {
        let center = DeviceActivityCenter()
        center.stopMonitoring([activityName])

        guard !apps.isEmpty else {
            let msg = "checkpoint_unavailable reason=no_tracked_apps"
            suite?.set("checkpoint_unavailable", forKey: statusKey)
            suite?.set(msg, forKey: lastErrorKey)
            suite?.set("duration", forKey: thresholdUnitKey)
            return msg
        }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )

        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for app in apps {
            let name = DeviceActivityEvent.Name(app.id.uuidString)
            if #available(iOS 17.4, *) {
                events[name] = DeviceActivityEvent(
                    applications: [app.token],
                    threshold: DateComponents(minute: 1),
                    includesPastActivity: false
                )
            } else {
                events[name] = DeviceActivityEvent(
                    applications: [app.token],
                    threshold: DateComponents(minute: 1)
                )
            }
        }

        do {
            try center.startMonitoring(activityName, during: schedule, events: events)
            suite?.set("monitoring", forKey: statusKey)
            suite?.removeObject(forKey: lastErrorKey)
            suite?.set("duration", forKey: thresholdUnitKey)
            let labels = apps.map(\.userLabel).joined(separator: ",")
            let note = "monitor_started apps=\(apps.count) labels=[\(labels)] threshold_s=\(thresholdSeconds) unit=duration includes_past=false once_per_interval"
            suite?.set(note, forKey: lastNoteKey)
            return nil
        } catch {
            let msg = "checkpoint_unavailable error=\(error)"
            suite?.set("checkpoint_unavailable", forKey: statusKey)
            suite?.set(msg, forKey: lastErrorKey)
            suite?.set("duration", forKey: thresholdUnitKey)
            return msg
        }
    }

    /// Host only. Stops the checkpoint schedule. Wall activities are left alone.
    static func stop() {
        DeviceActivityCenter().stopMonitoring([activityName])
        suite?.set("stopped", forKey: statusKey)
        suite?.removeObject(forKey: lastErrorKey)
        suite?.set("monitor_stopped", forKey: lastNoteKey)
    }

    /// Extension: duration threshold reached. Writes a usage_checkpoint. Never re-shields.
    static func recordThreshold(eventRaw: String) {
        let at = Date()
        let iso = ISO8601DateFormatter().string(from: at)
        guard let data = suite?.data(forKey: ShieldCopySettings.trackedAppsKey),
              let apps = try? JSONDecoder().decode([TrackedApp].self, from: data),
              let uuid = UUID(uuidString: eventRaw),
              let app = apps.first(where: { $0.id == uuid })
        else {
            suite?.set(
                "checkpoint_ignored reason=not_tracked event=\(eventRaw) at=\(iso)",
                forKey: lastNoteKey
            )
            return
        }

        let duplicate = TodayEventLog.load().contains {
            $0.type == "usage_checkpoint"
                && $0.trackedAppId == app.id
                && abs($0.timestamp.timeIntervalSince(at)) < 3
        }
        if !duplicate {
            TodayEventLog.append(
                type: "usage_checkpoint",
                trackedAppId: app.id,
                userLabel: app.userLabel,
                durationSeconds: thresholdSeconds,
                meta: "threshold_unit=duration side_signal=true not_open not_session",
                at: at
            )
        }
        suite?.set(iso, forKey: lastCheckpointAtKey)
        suite?.set(
            "usage_checkpoint label=\(app.userLabel) id=\(app.id.uuidString) threshold_s=\(thresholdSeconds) unit=duration at=\(iso) not_open not_session",
            forKey: lastNoteKey
        )
    }

    /// Host: copy a new App Group note into the on-device ATTN-P10 log.
    static func flushHostNotes() {
        let note = suite?.string(forKey: lastNoteKey) ?? ""
        guard !note.isEmpty else { return }
        let logged = suite?.string(forKey: lastHostLoggedNoteKey) ?? ""
        guard note != logged else { return }
        suite?.set(note, forKey: lastHostLoggedNoteKey)
        TestLogger.shared.log("ATTN-P10", note)
    }
}
