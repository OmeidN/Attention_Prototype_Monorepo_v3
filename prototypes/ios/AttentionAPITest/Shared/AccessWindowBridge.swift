import Foundation
import ManagedSettings

/// App Group state for Continue-triggered access windows (M09). Not opens / not session_end.
enum AccessWindowBridge {
    static let preferredDurationKey = "attention.m09.preferred_duration_seconds"
    static let activeKey = "attention.m09.window_active"
    static let startedAtKey = "attention.m09.window_started_at"
    static let endAtKey = "attention.m09.access_window_end_at"
    static let durationKey = "attention.m09.window_duration_seconds"
    static let trackedIdKey = "attention.m09.window_tracked_id"
    static let labelKey = "attention.m09.window_label"
    static let pendingReshieldKey = "attention.m09.pending_reshield"
    static let lastReshieldAtKey = "attention.m09.last_reshield_at"
    static let lastReshieldMechanismKey = "attention.m09.last_reshield_mechanism"
    static let lastHostLoggedStartAtKey = "attention.m09.last_host_logged_start_at"
    static let lastUsageCheckpointThresholdAtKey = "attention.m09.last_usage_checkpoint_threshold_at"
    static let honestUnitKey = "attention.m09.honest_unit_choice"

    /// Default for easy on-device P04 checks; Settings can pick 5/10/15 min.
    static let defaultDurationSeconds = 15

    static let durationChoices: [(label: String, seconds: Int)] = [
        ("15s debug", 15),
        ("1 min", 60),
        ("5 min", 300),
        ("10 min", 600),
        ("15 min", 900),
    ]

    static var suite: UserDefaults? { ShieldCopySettings.suite }

    static func preferredDurationSeconds() -> Int {
        let value = suite?.object(forKey: preferredDurationKey) as? Int
        return value ?? defaultDurationSeconds
    }

    static func setPreferredDurationSeconds(_ seconds: Int) {
        suite?.set(seconds, forKey: preferredDurationKey)
    }

    /// Called from ShieldActionExtension on Continue (after unblock).
    static func beginWindow(trackedAppId: UUID?, userLabel: String?, durationSeconds: Int? = nil) {
        let duration = durationSeconds ?? preferredDurationSeconds()
        let start = Date()
        let end = start.addingTimeInterval(TimeInterval(duration))
        let formatter = ISO8601DateFormatter()

        suite?.set(true, forKey: activeKey)
        suite?.set(false, forKey: pendingReshieldKey)
        suite?.set(formatter.string(from: start), forKey: startedAtKey)
        suite?.set(formatter.string(from: end), forKey: endAtKey)
        suite?.set(duration, forKey: durationKey)
        if let trackedAppId {
            suite?.set(trackedAppId.uuidString, forKey: trackedIdKey)
        } else {
            suite?.removeObject(forKey: trackedIdKey)
        }
        suite?.set(userLabel ?? "NO_LABEL", forKey: labelKey)
    }

    static func markPendingReshield() {
        suite?.set(true, forKey: pendingReshieldKey)
    }

    static func markReshielded(mechanism: String) {
        suite?.set(false, forKey: activeKey)
        suite?.set(false, forKey: pendingReshieldKey)
        suite?.set(ISO8601DateFormatter().string(from: Date()), forKey: lastReshieldAtKey)
        suite?.set(mechanism, forKey: lastReshieldMechanismKey)
    }

    static func clearWindow(reason: String) {
        _ = reason
        suite?.set(false, forKey: activeKey)
        suite?.set(false, forKey: pendingReshieldKey)
        suite?.removeObject(forKey: endAtKey)
    }

    static func endAtDate() -> Date? {
        guard let raw = suite?.string(forKey: endAtKey) else { return nil }
        return ISO8601DateFormatter().date(from: raw)
    }

    static func startedAtString() -> String? {
        suite?.string(forKey: startedAtKey)
    }

    static func isActive() -> Bool {
        suite?.bool(forKey: activeKey) == true
    }

    static func isPendingReshield() -> Bool {
        suite?.bool(forKey: pendingReshieldKey) == true
    }

    static func trackedId() -> UUID? {
        guard let raw = suite?.string(forKey: trackedIdKey) else { return nil }
        return UUID(uuidString: raw)
    }

    static func label() -> String {
        suite?.string(forKey: labelKey) ?? "NO_LABEL"
    }

    static func statusSummary() -> String {
        let active = isActive()
        let pending = isPendingReshield()
        let pref = preferredDurationSeconds()
        let dur = suite?.object(forKey: durationKey) as? Int ?? pref
        let start = suite?.string(forKey: startedAtKey) ?? "none"
        let end = suite?.string(forKey: endAtKey) ?? "none"
        let label = label()
        let id = suite?.string(forKey: trackedIdKey) ?? "nil"
        let mech = suite?.string(forKey: lastReshieldMechanismKey) ?? "none"
        let reshieldAt = suite?.string(forKey: lastReshieldAtKey) ?? "never"
        let remaining: String
        if let endDate = endAtDate(), active {
            let secs = Int(endDate.timeIntervalSinceNow)
            remaining = secs > 0 ? "\(secs)s" : "elapsed"
        } else {
            remaining = "n/a"
        }
        return """
        preferred_duration_s=\(pref)
        window_active=\(active) pending_reshield=\(pending) remaining=\(remaining)
        label=\(label) id=\(id) duration_s=\(dur)
        started_at=\(start)
        access_window_end_at=\(end)
        last_reshield=\(reshieldAt) mechanism=\(mech)
        unit=access_window (not open / not session_end)
        """
    }

    static func honestUnit() -> String {
        suite?.string(forKey: honestUnitKey) ?? "access_window"
    }

    static func setHonestUnit(_ unit: String) {
        suite?.set(unit, forKey: honestUnitKey)
    }
}
