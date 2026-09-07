import Foundation

/// App Group bridge between DeviceActivityMonitorExtension and the host (M07).
enum DeviceActivityBridge {
    static let activityNameRaw = "attention.m07.all_day"

    static let thresholdMinutesKey = "attention.m07.threshold_minutes"
    static let thresholdUnitClaimKey = "attention.m07.threshold_unit_claim"
    static let monitoringActiveKey = "attention.m07.monitoring_active"
    static let monitoringStartedAtKey = "attention.m07.monitoring_started_at"
    static let monitoredIdsKey = "attention.m07.monitored_tracked_ids"
    static let monitoredLabelsKey = "attention.m07.monitored_labels"

    static let lastIntervalStartKey = "attention.m07.last_interval_did_start"
    static let lastIntervalEndKey = "attention.m07.last_interval_did_end"
    static let lastThresholdAtKey = "attention.m07.last_event_did_reach_threshold"
    static let lastThresholdEventKey = "attention.m07.last_threshold_event"
    static let lastThresholdIdsKey = "attention.m07.last_threshold_tracked_ids"
    static let lastThresholdLabelsKey = "attention.m07.last_threshold_labels"
    static let lastCallbackKindKey = "attention.m07.last_callback_kind"
    static let callbackCountKey = "attention.m07.callback_count"

    /// Unhedged SDK fact (iPhoneOS26.5 / DeviceActivity): threshold is DateComponents only.
    static let thresholdUnitClaim =
        "duration — DeviceActivityEvent.threshold is DateComponents; no occurrence-count / N-opens API"

    static var suite: UserDefaults? { ShieldCopySettings.suite }

    static func writeThresholdClaim() {
        suite?.set(thresholdUnitClaim, forKey: thresholdUnitClaimKey)
    }

    static func recordIntervalStart(activity: String) {
        writeCallback(kind: "intervalDidStart", activity: activity, event: nil, ids: [], labels: [])
        suite?.set(ISO8601DateFormatter().string(from: Date()), forKey: lastIntervalStartKey)
    }

    static func recordIntervalEnd(activity: String) {
        writeCallback(kind: "intervalDidEnd", activity: activity, event: nil, ids: [], labels: [])
        suite?.set(ISO8601DateFormatter().string(from: Date()), forKey: lastIntervalEndKey)
    }

    static func recordThreshold(activity: String, eventRaw: String) {
        let (ids, labels) = resolveEvent(eventRaw)
        writeCallback(kind: "eventDidReachThreshold", activity: activity, event: eventRaw, ids: ids, labels: labels)
        suite?.set(ISO8601DateFormatter().string(from: Date()), forKey: lastThresholdAtKey)
        suite?.set(eventRaw, forKey: lastThresholdEventKey)
        suite?.set(ids.joined(separator: ","), forKey: lastThresholdIdsKey)
        suite?.set(labels.joined(separator: ","), forKey: lastThresholdLabelsKey)
    }

    static func markMonitoringStarted(ids: [String], labels: [String], thresholdMinutes: Int) {
        writeThresholdClaim()
        suite?.set(true, forKey: monitoringActiveKey)
        suite?.set(ISO8601DateFormatter().string(from: Date()), forKey: monitoringStartedAtKey)
        suite?.set(thresholdMinutes, forKey: thresholdMinutesKey)
        suite?.set(ids.joined(separator: ","), forKey: monitoredIdsKey)
        suite?.set(labels.joined(separator: ","), forKey: monitoredLabelsKey)
    }

    static func markMonitoringStopped() {
        suite?.set(false, forKey: monitoringActiveKey)
    }

    static func statusSummary() -> String {
        let active = suite?.bool(forKey: monitoringActiveKey) == true
        let started = suite?.string(forKey: monitoringStartedAtKey) ?? "never"
        let minutes = suite?.object(forKey: thresholdMinutesKey) as? Int ?? 1
        let labels = suite?.string(forKey: monitoredLabelsKey) ?? ""
        let intervalStart = suite?.string(forKey: lastIntervalStartKey) ?? "none"
        let intervalEnd = suite?.string(forKey: lastIntervalEndKey) ?? "none"
        let thresholdAt = suite?.string(forKey: lastThresholdAtKey) ?? "none"
        let thresholdEvent = suite?.string(forKey: lastThresholdEventKey) ?? "none"
        let thresholdLabels = suite?.string(forKey: lastThresholdLabelsKey) ?? ""
        let kind = suite?.string(forKey: lastCallbackKindKey) ?? "none"
        let count = suite?.integer(forKey: callbackCountKey) ?? 0
        return """
        monitoring_active=\(active)
        started_at=\(started)
        threshold_minutes=\(minutes)
        monitored_labels=[\(labels)]
        last_callback=\(kind) count=\(count)
        intervalDidStart=\(intervalStart)
        intervalDidEnd=\(intervalEnd)
        eventDidReachThreshold=\(thresholdAt)
        last_threshold_event=\(thresholdEvent) labels=[\(thresholdLabels)]
        """
    }

    static func waitingSinceLine() -> String {
        guard suite?.bool(forKey: monitoringActiveKey) == true,
              let started = suite?.string(forKey: monitoringStartedAtKey),
              let date = ISO8601DateFormatter().date(from: started)
        else { return "waiting_since=n/a (not monitoring)" }
        let elapsed = Int(Date().timeIntervalSince(date))
        let hasThreshold = suite?.string(forKey: lastThresholdAtKey) != nil
        return "waiting_since=\(started) elapsed≈\(elapsed)s threshold_seen=\(hasThreshold)"
    }

    private static func writeCallback(
        kind: String,
        activity: String,
        event: String?,
        ids: [String],
        labels: [String]
    ) {
        let count = (suite?.integer(forKey: callbackCountKey) ?? 0) + 1
        suite?.set(count, forKey: callbackCountKey)
        suite?.set(kind, forKey: lastCallbackKindKey)
        _ = activity
        _ = event
        _ = ids
        _ = labels
    }

    private static func resolveEvent(_ eventRaw: String) -> (ids: [String], labels: [String]) {
        guard let data = suite?.data(forKey: ShieldCopySettings.trackedAppsKey),
              let apps = try? JSONDecoder().decode([TrackedApp].self, from: data)
        else { return ([eventRaw], []) }

        if let uuid = UUID(uuidString: eventRaw),
           let app = apps.first(where: { $0.id == uuid }) {
            return ([app.id.uuidString], [app.userLabel])
        }
        return ([eventRaw], [])
    }
}
