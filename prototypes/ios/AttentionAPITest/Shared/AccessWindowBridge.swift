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

    /// Which app the last close belonged to — the legacy `trackedIdKey` is the *latest Continue*,
    /// which is a different app once two windows can be open at once.
    static let lastReshieldAppIdKey = "attention.p04.last_reshield_app_id"
    static let lastReshieldLabelKey = "attention.p04.last_reshield_label"
    static let lastReshieldElapsedKey = "attention.p04.last_reshield_elapsed_s"

    /// JSON map appUUID → OpenWindow. Per-app so a second Continue cannot overwrite the first
    /// app's start time (window elapsed would then be attributed to the wrong app).
    static let openWindowsMapKey = "attention.p04.open_windows_v1"

    struct OpenWindow: Codable {
        var appID: String
        var label: String
        var startedAt: String
        var endAt: String
        var plannedSeconds: Int
    }

    /// Default for easy on-device P04 checks; Settings can pick 5/10/15 min.
    static let defaultDurationSeconds = 15

    static let durationChoices: [(label: String, seconds: Int)] = [
        ("15s debug", 15),
        ("1 min", 60),
        ("3 min", 180),
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

        if let trackedAppId {
            var open = loadOpenWindows()
            open[trackedAppId.uuidString] = OpenWindow(
                appID: trackedAppId.uuidString,
                label: userLabel ?? "NO_LABEL",
                startedAt: formatter.string(from: start),
                endAt: formatter.string(from: end),
                plannedSeconds: duration
            )
            saveOpenWindows(open)
        }

        TodayEventLog.append(
            type: "access_window_start",
            trackedAppId: trackedAppId,
            userLabel: userLabel ?? "NO_LABEL",
            durationSeconds: duration,
            meta: "beginWindow",
            at: start
        )
    }

    // MARK: - Per-app open windows

    static func loadOpenWindows() -> [String: OpenWindow] {
        guard let data = suite?.data(forKey: openWindowsMapKey),
              let decoded = try? JSONDecoder().decode([String: OpenWindow].self, from: data)
        else { return [:] }
        return decoded
    }

    static func saveOpenWindows(_ map: [String: OpenWindow]) {
        if map.isEmpty {
            suite?.removeObject(forKey: openWindowsMapKey)
            return
        }
        if let data = try? JSONEncoder().encode(map) {
            suite?.set(data, forKey: openWindowsMapKey)
        }
    }

    static func openWindow(forAppID id: UUID) -> OpenWindow? {
        loadOpenWindows()[id.uuidString]
    }

    static func openWindowAppIDs() -> Set<UUID> {
        Set(loadOpenWindows().keys.compactMap { UUID(uuidString: $0) })
    }

    static func hasOpenWindows() -> Bool {
        !loadOpenWindows().isEmpty
    }

    static func openWindowLabels() -> [String] {
        loadOpenWindows().values.map(\.label).sorted()
    }

    /// Drop one app's open window without touching the others (host abandon / manual shield).
    @discardableResult
    static func clearOpenWindow(forAppID id: UUID) -> OpenWindow? {
        var open = loadOpenWindows()
        let removed = open.removeValue(forKey: id.uuidString)
        saveOpenWindows(open)
        return removed
    }

    /// Manual shield / pause ends every open window — log each one so Home keeps real elapsed time
    /// instead of leaving stale entries that would bill a later close.
    @discardableResult
    static func closeAllOpenWindows(mechanism: String) -> [String] {
        let open = loadOpenWindows()
        guard !open.isEmpty else { return [] }
        var labels: [String] = []
        for (key, entry) in open {
            guard let id = UUID(uuidString: key) else { continue }
            markReshielded(mechanism: mechanism, trackedAppId: id, userLabel: entry.label)
            labels.append(entry.label)
        }
        saveOpenWindows([:])
        return labels.sorted()
    }

    static func markPendingReshield() {
        suite?.set(true, forKey: pendingReshieldKey)
    }

    /// Close one app's window and log its elapsed time. `trackedAppId` matters once two
    /// windows can be open — without it we would bill this close to the latest Continue.
    static func markReshielded(
        mechanism: String,
        trackedAppId: UUID? = nil,
        userLabel: String? = nil,
        startedAtISO: String? = nil
    ) {
        let end = Date()
        let iso = ISO8601DateFormatter()
        let id = trackedAppId ?? trackedId()

        let openEntry = id.flatMap { clearOpenWindow(forAppID: $0) }
        let lbl = userLabel ?? openEntry?.label ?? label()

        var elapsed: Int?
        let startRaw = startedAtISO ?? openEntry?.startedAt ?? suite?.string(forKey: startedAtKey)
        if let startRaw, let start = iso.date(from: startRaw) {
            elapsed = max(0, Int(end.timeIntervalSince(start)))
        } else if let planned = openEntry?.plannedSeconds ?? suite?.object(forKey: durationKey) as? Int {
            elapsed = planned
        }

        // Other apps may still be mid-window.
        suite?.set(hasOpenWindows(), forKey: activeKey)
        suite?.set(false, forKey: pendingReshieldKey)
        suite?.set(iso.string(from: end), forKey: lastReshieldAtKey)
        suite?.set(mechanism, forKey: lastReshieldMechanismKey)
        suite?.set(id?.uuidString ?? "", forKey: lastReshieldAppIdKey)
        suite?.set(lbl, forKey: lastReshieldLabelKey)
        suite?.set(elapsed ?? -1, forKey: lastReshieldElapsedKey)

        TodayEventLog.append(
            type: "access_window_end",
            trackedAppId: id,
            userLabel: lbl,
            durationSeconds: elapsed,
            meta: "mechanism=\(mechanism)",
            at: end
        )
        TodayEventLog.append(
            type: "reshield_debug",
            trackedAppId: id,
            userLabel: lbl,
            meta: mechanism,
            at: end
        )
    }

    /// Legacy single-slot flags only. Never drops per-app open windows — those hold the start
    /// timestamps the wall close needs to compute elapsed.
    static func clearWindow(reason: String) {
        _ = reason
        suite?.set(hasOpenWindows(), forKey: activeKey)
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
        let openLabels = openWindowLabels()
        let openNote = openLabels.isEmpty ? "open_windows=none" : "open_windows=[\(openLabels.joined(separator: ","))]"
        return """
        preferred_duration_s=\(pref)
        window_active=\(active) pending_reshield=\(pending) remaining=\(remaining)
        \(openNote)
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
