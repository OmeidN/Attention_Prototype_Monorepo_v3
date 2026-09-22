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

        let appID: UUID?
        if let activityRaw, let parsed = HardWindowMonitor.appID(fromWallActivityRaw: activityRaw) {
            appID = parsed
        } else {
            appID = HardWindowMonitor.pendingWallAppID()
        }
        guard let appID else { return false }
        guard let data = suite?.data(forKey: ShieldCopySettings.trackedAppsKey),
              let apps = try? JSONDecoder().decode([TrackedApp].self, from: data),
              let match = apps.first(where: { $0.id == appID })
        else { return false }

        return applyHardReshield(targets: [match], reason: "wall_clock")
    }

    private static func applyHardReshield(targets: [TrackedApp], reason: String) -> Bool {
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
            HardWindowMonitor.clearWallPending(reason: "after_\(reason)", appID: app.id)
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
