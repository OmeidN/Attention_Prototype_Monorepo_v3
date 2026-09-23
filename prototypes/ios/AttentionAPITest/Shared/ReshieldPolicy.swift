import Foundation
import ManagedSettings

/// M10 re-shield policy. Default does not yank mid-use (`unsafe_interrupt=false`).
enum ReshieldMode: String, CaseIterable, Identifiable {
    case onWindowEnd = "on_window_end"
    case onThreshold = "on_threshold"
    case manualOnly = "manual_only"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .onWindowEnd: return "window end"
        case .onThreshold: return "threshold"
        case .manualOnly: return "manual only"
        }
    }
}

enum ReshieldPolicy {
    static let modeKey = "attention.m10.reshield_mode"
    static let unsafeInterruptKey = "attention.m10.unsafe_interrupt"
    static let pendingThresholdKey = "attention.m10.pending_threshold_reshield"
    static let pendingThresholdAtKey = "attention.m10.pending_threshold_at"
    static let pendingThresholdEventKey = "attention.m10.pending_threshold_event"
    static let pendingThresholdLabelsKey = "attention.m10.pending_threshold_labels"
    static let lastModeKey = "attention.m10.last_reshield_mode"
    static let lastReasonKey = "attention.m10.last_reshield_reason"
    static let lastAppliedAtKey = "attention.m10.reshield_applied_at"
    static let extensionAppliedKey = "attention.m10.last_extension_applied"
    static let acceptableModeKey = "attention.m10.acceptable_mode_for_production"

    static var suite: UserDefaults? { ShieldCopySettings.suite }

    static func mode() -> ReshieldMode {
        guard let raw = suite?.string(forKey: modeKey),
              let mode = ReshieldMode(rawValue: raw)
        else { return .onWindowEnd }
        return mode
    }

    static func setMode(_ mode: ReshieldMode) {
        suite?.set(mode.rawValue, forKey: modeKey)
    }

    static func unsafeInterrupt() -> Bool {
        suite?.bool(forKey: unsafeInterruptKey) == true
    }

    static func setUnsafeInterrupt(_ on: Bool) {
        suite?.set(on, forKey: unsafeInterruptKey)
    }

    static func acceptableModeNote() -> String {
        suite?.string(forKey: acceptableModeKey) ?? ""
    }

    static func setAcceptableModeNote(_ note: String) {
        suite?.set(note, forKey: acceptableModeKey)
    }

    static func markPendingThreshold(eventRaw: String, labels: [String]) {
        suite?.set(true, forKey: pendingThresholdKey)
        suite?.set(ISO8601DateFormatter().string(from: Date()), forKey: pendingThresholdAtKey)
        suite?.set(eventRaw, forKey: pendingThresholdEventKey)
        suite?.set(labels.joined(separator: ","), forKey: pendingThresholdLabelsKey)
    }

    static func clearPendingThreshold() {
        suite?.set(false, forKey: pendingThresholdKey)
    }

    static func isPendingThreshold() -> Bool {
        suite?.bool(forKey: pendingThresholdKey) == true
    }

    static func recordApplied(
        mode: ReshieldMode,
        reason: String,
        fromExtension: Bool,
        appID: UUID? = nil,
        userLabel: String? = nil,
        startedAtISO: String? = nil
    ) {
        let at = ISO8601DateFormatter().string(from: Date())
        suite?.set(mode.rawValue, forKey: lastModeKey)
        suite?.set(reason, forKey: lastReasonKey)
        suite?.set(at, forKey: lastAppliedAtKey)
        suite?.set(fromExtension, forKey: extensionAppliedKey)
        AccessWindowBridge.markReshielded(
            mechanism: "m10_\(mode.rawValue)_\(reason)",
            trackedAppId: appID,
            userLabel: userLabel,
            startedAtISO: startedAtISO
        )
        clearPendingThreshold()
    }

    static func statusSummary() -> String {
        let mode = mode()
        let unsafe = unsafeInterrupt()
        let pending = isPendingThreshold()
        let lastMode = suite?.string(forKey: lastModeKey) ?? "none"
        let lastReason = suite?.string(forKey: lastReasonKey) ?? "none"
        let lastAt = suite?.string(forKey: lastAppliedAtKey) ?? "never"
        let fromExt = suite?.bool(forKey: extensionAppliedKey) == true
        let acceptable = acceptableModeNote().isEmpty ? "(unset)" : acceptableModeNote()
        return """
        reshield_mode=\(mode.rawValue)
        unsafe_interrupt=\(unsafe) (default false — do not yank mid-use)
        pending_threshold_reshield=\(pending)
        last_reshield_mode=\(lastMode)
        last_reshield_reason=\(lastReason)
        reshield_applied_at=\(lastAt) from_extension=\(fromExt)
        production_acceptable=\(acceptable)
        """
    }

    /// Monitor extension: usage threshold path (disabled — wall-only closer).
    static func tryReshieldFromMonitorExtension(eventRaw: String, ids: [String], labels: [String]) -> Bool {
        guard HardWindowMonitor.usageCloserEnabled else {
            HardWindowMonitor.suite?.set("usage_disabled", forKey: HardWindowMonitor.lastUsageThresholdDecisionKey)
            return false
        }
        guard mode() == .onThreshold else {
            HardWindowMonitor.suite?.set("wrong_mode", forKey: HardWindowMonitor.lastUsageThresholdDecisionKey)
            return false
        }

        if HardWindowMonitor.shouldIgnorePrematureUsageThreshold() {
            HardWindowMonitor.suite?.set("premature", forKey: HardWindowMonitor.lastUsageThresholdDecisionKey)
            return false
        }

        markPendingThreshold(eventRaw: eventRaw, labels: labels)

        guard let data = suite?.data(forKey: ShieldCopySettings.trackedAppsKey),
              let apps = try? JSONDecoder().decode([TrackedApp].self, from: data)
        else {
            HardWindowMonitor.suite?.set("no_targets", forKey: HardWindowMonitor.lastUsageThresholdDecisionKey)
            return false
        }

        let targets: [TrackedApp]
        if let uuid = UUID(uuidString: eventRaw),
           let match = apps.first(where: { $0.id == uuid }) {
            targets = [match]
        } else if let firstLabel = labels.first,
                  let match = apps.first(where: { $0.userLabel == firstLabel }) {
            targets = [match]
        } else if let id = ids.first, let uuid = UUID(uuidString: id),
                  let match = apps.first(where: { $0.id == uuid }) {
            targets = [match]
        } else {
            targets = []
        }

        guard !targets.isEmpty else {
            HardWindowMonitor.suite?.set("no_targets", forKey: HardWindowMonitor.lastUsageThresholdDecisionKey)
            return false
        }

        let ok = applyHardReshield(targets: targets, reason: "usage_threshold")
        HardWindowMonitor.suite?.set(ok ? "applied" : "apply_failed", forKey: HardWindowMonitor.lastUsageThresholdDecisionKey)
        return ok
    }

    /// Wall-clock interval ended — re-shield that Continued app only (other walls keep running).
    static func tryWallReshieldFromMonitorExtension(activityRaw: String? = nil) -> Bool {
        guard mode() == .onThreshold else { return false }
        if HardWindowMonitor.suppressWallCallbacks {
            HardWindowMonitor.suite?.set(
                "wall_ignored_reentrant activity=\(activityRaw ?? "nil") at=\(ISO8601DateFormatter().string(from: Date()))",
                forKey: HardWindowMonitor.wallArmSummaryKey
            )
            return false
        }

        guard let activityRaw, let parsed = HardWindowMonitor.parseWallActivity(activityRaw) else {
            // Legacy single wall name cannot name the app. A stale callback was re-shielding
            // whoever Continue had just armed.
            HardWindowMonitor.suite?.set(
                "wall_ignored_legacy activity=\(activityRaw ?? "nil") at=\(ISO8601DateFormatter().string(from: Date()))",
                forKey: HardWindowMonitor.wallArmSummaryKey
            )
            return false
        }
        let appID = parsed.appID
        // End time lives on the activity name so a stale UserDefaults pending map cannot
        // make a ~30s past-pad callback look like the real wall.
        if let namedEnd = parsed.endEpoch {
            let remaining = Int(namedEnd - Date().timeIntervalSince1970)
            if remaining > HardWindowMonitor.wallEarlyIgnoreSlackSeconds {
                HardWindowMonitor.suite?.set(
                    "wall_ignored_named_early session=\(parsed.session.map(String.init) ?? "none") remaining_s=\(remaining) end_epoch=\(Int(namedEnd)) at=\(ISO8601DateFormatter().string(from: Date()))",
                    forKey: HardWindowMonitor.wallArmSummaryKey
                )
                return false
            }
        } else {
            HardWindowMonitor.suite?.set(
                "wall_ignored_unnamed_end activity=\(activityRaw) at=\(ISO8601DateFormatter().string(from: Date()))",
                forKey: HardWindowMonitor.wallArmSummaryKey
            )
            return false
        }
        // Fail closed. A missing/stale live marker used to let an old intervalDidEnd
        // match the old pending row and wipe the wall Continue just armed.
        let live = HardWindowMonitor.readLiveMarker(appID: appID)
        guard let callbackSession = parsed.session,
              let live,
              live.session == callbackSession
        else {
            HardWindowMonitor.suite?.set(
                "wall_ignored_live_mismatch callback_session=\(parsed.session.map(String.init) ?? "none") live_session=\(live.map { String($0.session) } ?? "none") at=\(ISO8601DateFormatter().string(from: Date()))",
                forKey: HardWindowMonitor.wallArmSummaryKey
            )
            return false
        }
        if let namedEnd = parsed.endEpoch, abs(live.endEpoch - namedEnd) > 2 {
            HardWindowMonitor.suite?.set(
                "wall_ignored_live_end_mismatch live_end=\(Int(live.endEpoch)) named_end=\(Int(namedEnd)) at=\(ISO8601DateFormatter().string(from: Date()))",
                forKey: HardWindowMonitor.wallArmSummaryKey
            )
            return false
        }
        if let pending = HardWindowMonitor.pendingWall(forAppID: appID),
           parsed.session != pending.session {
            HardWindowMonitor.suite?.set(
                "wall_ignored_stale_session label=\(pending.label) callback_session=\(parsed.session.map(String.init) ?? "none") armed_session=\(pending.session) at=\(ISO8601DateFormatter().string(from: Date()))",
                forKey: HardWindowMonitor.wallArmSummaryKey
            )
            return false
        }
        guard let data = suite?.data(forKey: ShieldCopySettings.trackedAppsKey),
              let apps = try? JSONDecoder().decode([TrackedApp].self, from: data),
              let match = apps.first(where: { $0.id == appID })
        else {
            HardWindowMonitor.suite?.set(
                "wall_ignored_no_app id=\(appID.uuidString) at=\(ISO8601DateFormatter().string(from: Date()))",
                forKey: HardWindowMonitor.wallArmSummaryKey
            )
            return false
        }

        let due = HardWindowMonitor.wallEndIsDue(appID: appID)
        guard due.due else {
            let note = due.note
            // Do not re-arm here. armWallClock used to stopMonitoring the prior name and
            // that re-delivered intervalDidEnd, which is what wiped the second wall.
            HardWindowMonitor.suite?.set(
                "\(note) at=\(ISO8601DateFormatter().string(from: Date()))",
                forKey: HardWindowMonitor.wallArmSummaryKey
            )
            return false
        }

        let applied = applyHardReshield(targets: [match], reason: "wall_clock", expectedSession: parsed.session)
        if applied {
            _ = catchUpDueWalls(apps: apps, source: "monitor", except: appID)
        }
        return applied
    }

    /// Host / monitor fallback when DeviceActivity drops a second `intervalDidEnd`
    /// (same hour:minute slot, or a stale close wiped the first callback's twin).
    @discardableResult
    static func catchUpDueWalls(apps: [TrackedApp], source: String, except: UUID? = nil) -> [String] {
        guard mode() == .onThreshold else { return [] }
        var closed: [String] = []
        for pending in HardWindowMonitor.loadPendingMap().values {
            guard let id = UUID(uuidString: pending.appID), id != except,
                  let match = apps.first(where: { $0.id == id })
            else { continue }
            let due = HardWindowMonitor.wallEndIsDue(appID: id)
            guard due.due else { continue }
            if applyHardReshield(targets: [match], reason: "wall_catchup_\(source)", expectedSession: pending.session) {
                closed.append(match.userLabel)
            }
        }
        if !closed.isEmpty {
            HardWindowMonitor.suite?.set(
                "wall_catchup source=\(source) labels=[\(closed.joined(separator: ","))] at=\(ISO8601DateFormatter().string(from: Date()))",
                forKey: HardWindowMonitor.wallArmSummaryKey
            )
        }
        return closed
    }

    private static func applyHardReshield(targets: [TrackedApp], reason: String, expectedSession: Int? = nil) -> Bool {
        if let expectedSession, let app = targets.first {
            let disk = HardWindowMonitor.pendingWall(forAppID: app.id)?.session
            if disk != expectedSession {
                HardWindowMonitor.suite?.set(
                    "wall_clear_aborted reason=before_shield expected_session=\(expectedSession) disk_session=\(disk.map(String.init) ?? "none") label=\(app.userLabel)",
                    forKey: HardWindowMonitor.wallArmSummaryKey
                )
                return false
            }
        }
        let store = ManagedSettingsStore()
        var applications = store.shield.applications ?? Set()
        for app in targets {
            applications.insert(app.token)
        }
        store.shield.applications = applications
        suite?.set(true, forKey: "attention.m04.last_shield_write_active")

        // Close only this app's window — other apps may still be mid-window.
        if let app = targets.first {
            let openStart = AccessWindowBridge.openWindow(forAppID: app.id)?.startedAt
            recordApplied(
                mode: .onThreshold,
                reason: "monitor_extension_\(reason)",
                fromExtension: true,
                appID: app.id,
                userLabel: app.userLabel,
                startedAtISO: openStart == nil ? HardWindowMonitor.pendingWall(forAppID: app.id)?.continuedAt : nil
            )
            let cleared = HardWindowMonitor.clearWallPending(reason: "after_\(reason)", appID: app.id, expectedSession: expectedSession)
            if !cleared {
                var rolledBack = store.shield.applications ?? Set()
                rolledBack.remove(app.token)
                store.shield.applications = rolledBack.isEmpty ? nil : rolledBack
                return false
            }
        } else {
            recordApplied(mode: .onThreshold, reason: "monitor_extension_\(reason)", fromExtension: true)
            HardWindowMonitor.clearWallPending(reason: "after_\(reason)")
        }

        suite?.set(
            "ATTN-P05B hard_reshield reason=\(reason) labels=[\(targets.map(\.userLabel).joined(separator: ","))] — wall-only closer not opens",
            forKey: "attention.p05a.last_hard_reshield_note"
        )
        suite?.set(
            "\(reason) labels=[\(targets.map(\.userLabel).joined(separator: ","))] at=\(ISO8601DateFormatter().string(from: Date()))",
            forKey: HardWindowMonitor.lastHybridCloseKey
        )
        return true
    }
}
