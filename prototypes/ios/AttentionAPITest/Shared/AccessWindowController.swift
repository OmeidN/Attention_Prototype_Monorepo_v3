import Foundation
import Combine
import ManagedSettings

/// Host-side access window timer + M10 re-shield modes.
@MainActor
final class AccessWindowController: ObservableObject {
    static let shared = AccessWindowController()

    @Published var durationSeconds: Int
    @Published var honestUnit: String
    @Published var reshieldMode: ReshieldMode
    @Published var unsafeInterrupt: Bool
    @Published var acceptableModeNote: String
    @Published private(set) var statusText: String
    @Published private(set) var reshieldStatusText: String
    @Published private(set) var ruleText: String

    private var timer: Timer?
    private var attentionForeground = true

    private init() {
        let mode = ReshieldPolicy.mode()
        let unsafe = ReshieldPolicy.unsafeInterrupt()
        durationSeconds = AccessWindowBridge.preferredDurationSeconds()
        honestUnit = AccessWindowBridge.honestUnit()
        reshieldMode = mode
        unsafeInterrupt = unsafe
        acceptableModeNote = ReshieldPolicy.acceptableModeNote()
        statusText = AccessWindowBridge.statusSummary()
        reshieldStatusText = ReshieldPolicy.statusSummary()
        ruleText = Self.makeRuleText(mode: mode, unsafe: unsafe)
    }

    func setDurationSeconds(_ seconds: Int) {
        durationSeconds = seconds
        AccessWindowBridge.setPreferredDurationSeconds(seconds)
        TestLogger.shared.log("ATTN-M09", "preferred_duration_s=\(seconds)")
        TestLogger.shared.log("ATTN-P04", "preferred_duration_s=\(seconds)")
        refreshStatus()
    }

    func setHonestUnit(_ unit: String) {
        honestUnit = unit
        AccessWindowBridge.setHonestUnit(unit)
        TestLogger.shared.log("ATTN-M09", "honest_unit_choice=\(unit)")
    }

    func setReshieldMode(_ mode: ReshieldMode) {
        reshieldMode = mode
        ReshieldPolicy.setMode(mode)
        ruleText = Self.makeRuleText(mode: mode, unsafe: unsafeInterrupt)
        TestLogger.shared.log("ATTN-M10", "reshield_mode=\(mode.rawValue) unsafe_interrupt=\(unsafeInterrupt)")
        refreshStatus()
    }

    func setUnsafeInterrupt(_ on: Bool) {
        unsafeInterrupt = on
        ReshieldPolicy.setUnsafeInterrupt(on)
        ruleText = Self.makeRuleText(mode: reshieldMode, unsafe: on)
        TestLogger.shared.log(
            "ATTN-M10",
            "unsafe_interrupt=\(on) — \(on ? "WILL yank while tracked app may be foreground" : "default safe defer")"
        )
        refreshStatus()
    }

    func setAcceptableModeNote(_ note: String) {
        acceptableModeNote = note
        ReshieldPolicy.setAcceptableModeNote(note)
        TestLogger.shared.log("ATTN-M10", "production_acceptable=\(note)")
        refreshStatus()
    }

    func sync(reason: String, attentionForeground: Bool, apps: [TrackedApp]) {
        self.attentionForeground = attentionForeground
        logWindowStartIfNeeded(reason: reason)
        consumePendingThresholdIfNeeded(reason: reason, apps: apps)
        refreshStatus()

        if AccessWindowBridge.isPendingReshield() || windowElapsed() {
            handleWindowEnd(reason: reason, apps: apps)
            return
        }

        if AccessWindowBridge.isActive() {
            scheduleTimer(apps: apps)
        } else {
            cancelTimer()
        }
    }

    /// Debug: arm a window for an already-unblocked tracked app without shield Continue.
    func debugStartWindow(for app: TrackedApp) {
        AccessWindowBridge.beginWindow(trackedAppId: app.id, userLabel: app.userLabel)
        TestLogger.shared.log(
            "ATTN-M09",
            "window_start source=debug_button label=\(app.userLabel) id=\(app.id.uuidString) duration_s=\(AccessWindowBridge.preferredDurationSeconds()) end_at=\(AccessWindowBridge.suite?.string(forKey: AccessWindowBridge.endAtKey) ?? "?")"
        )
        AccessWindowBridge.suite?.set(
            AccessWindowBridge.startedAtString(),
            forKey: AccessWindowBridge.lastHostLoggedStartAtKey
        )
        refreshStatus()
        scheduleTimer(apps: [app])
    }

    func cancelActiveWindow(reason: String) {
        cancelTimer()
        AccessWindowBridge.clearWindow(reason: reason)
        TestLogger.shared.log("ATTN-M09", "window_cancel reason=\(reason)")
        refreshStatus()
    }

    func manualReshieldNow(apps: [TrackedApp]) {
        let mode = ReshieldPolicy.mode()
        guard mode == .manualOnly || mode == .onWindowEnd || mode == .onThreshold else { return }
        performReshield(
            apps: apps,
            mode: .manualOnly,
            reason: "manual_button",
            mechanism: "manual_button",
            logTag: "ATTN-M10"
        )
    }

    func noteUsageCheckpointIfNeeded(thresholdAt: String, labels: String, reason: String) {
        let last = AccessWindowBridge.suite?.string(forKey: AccessWindowBridge.lastUsageCheckpointThresholdAtKey)
        guard last != thresholdAt else { return }
        AccessWindowBridge.suite?.set(thresholdAt, forKey: AccessWindowBridge.lastUsageCheckpointThresholdAtKey)

        let inWindow = AccessWindowBridge.isActive()
        let endAt = AccessWindowBridge.suite?.string(forKey: AccessWindowBridge.endAtKey) ?? "none"
        TestLogger.shared.log(
            "ATTN-M09",
            "usage_checkpoint threshold_at=\(thresholdAt) labels=[\(labels)] in_access_window=\(inWindow) access_window_end_at=\(endAt) reason=\(reason) — usage_time not session_end"
        )

        if ReshieldPolicy.mode() == .onThreshold {
            consumePendingThresholdIfNeeded(reason: "usage_checkpoint_\(reason)", apps: TrackedAppsStore.shared.apps)
        }
    }

    private static func makeRuleText(mode: ReshieldMode, unsafe: Bool) -> String {
        switch mode {
        case .onWindowEnd:
            return unsafe
                ? "UNSAFE: window end may re-shield while tracked app is foreground."
                : "on_window_end: re-shield after window when Attention is active (defer if background). No mid-use yank."
        case .onThreshold:
            return "on_threshold: host window end does NOT re-shield; each Continue's own wall-clock closes that app from the monitor extension."
        case .manualOnly:
            return "manual_only: window end does NOT re-shield; use Manual re-shield button."
        }
    }

    private func logWindowStartIfNeeded(reason: String) {
        guard AccessWindowBridge.isActive(),
              let started = AccessWindowBridge.startedAtString()
        else { return }
        let logged = AccessWindowBridge.suite?.string(forKey: AccessWindowBridge.lastHostLoggedStartAtKey)
        guard logged != started else { return }
        AccessWindowBridge.suite?.set(started, forKey: AccessWindowBridge.lastHostLoggedStartAtKey)
        let end = AccessWindowBridge.suite?.string(forKey: AccessWindowBridge.endAtKey) ?? "?"
        let dur = AccessWindowBridge.suite?.object(forKey: AccessWindowBridge.durationKey) as? Int ?? 0
        TestLogger.shared.log(
            "ATTN-M09",
            "window_start source=continue_bridge reason=\(reason) label=\(AccessWindowBridge.label()) id=\(AccessWindowBridge.suite?.string(forKey: AccessWindowBridge.trackedIdKey) ?? "nil") duration_s=\(dur) access_window_end_at=\(end)"
        )
        TestLogger.shared.log(
            "ATTN-P04",
            "window_start source=continue_bridge reason=\(reason) label=\(AccessWindowBridge.label()) id=\(AccessWindowBridge.suite?.string(forKey: AccessWindowBridge.trackedIdKey) ?? "nil") duration_s=\(dur) access_window_end_at=\(end) unit=access_window"
        )
        TestLogger.shared.log(
            "ATTN-M10",
            "window_armed reshield_mode=\(ReshieldPolicy.mode().rawValue) unsafe_interrupt=\(ReshieldPolicy.unsafeInterrupt())"
        )
        TestLogger.shared.log(
            "ATTN-P04",
            "window_armed reshield_mode=\(ReshieldPolicy.mode().rawValue) unsafe_interrupt=\(ReshieldPolicy.unsafeInterrupt())"
        )
    }

    private func windowElapsed() -> Bool {
        guard AccessWindowBridge.isActive(), let end = AccessWindowBridge.endAtDate() else { return false }
        return end.timeIntervalSinceNow <= 0
    }

    private func scheduleTimer(apps: [TrackedApp]) {
        cancelTimer()
        guard let end = AccessWindowBridge.endAtDate(), AccessWindowBridge.isActive() else { return }
        let delay = max(0.05, end.timeIntervalSinceNow)
        let capturedApps = apps
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.handleWindowEnd(reason: "timer_fired", apps: capturedApps)
            }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func handleWindowEnd(reason: String, apps: [TrackedApp]) {
        guard AccessWindowBridge.isActive() || AccessWindowBridge.isPendingReshield() else {
            refreshStatus()
            return
        }

        let endAt = AccessWindowBridge.suite?.string(forKey: AccessWindowBridge.endAtKey) ?? "?"
        let label = AccessWindowBridge.label()
        let mode = ReshieldPolicy.mode()

        switch mode {
        case .manualOnly:
            cancelTimer()
            AccessWindowBridge.clearWindow(reason: "window_end_manual_only")
            TestLogger.shared.log(
                "ATTN-M10",
                "window_end no_reshield mode=manual_only label=\(label) access_window_end_at=\(endAt) reason=\(reason)"
            )
            refreshStatus()
            return

        case .onThreshold:
            cancelTimer()
            AccessWindowBridge.clearWindow(reason: "window_end_wait_wall")
            TestLogger.shared.log(
                "ATTN-M10",
                "window_end no_reshield mode=on_threshold waiting_for_wall_clock label=\(label) access_window_end_at=\(endAt) reason=\(reason) open_windows=[\(AccessWindowBridge.openWindowLabels().joined(separator: ","))]"
            )
            refreshStatus()
            return

        case .onWindowEnd:
            break
        }

        let unsafe = ReshieldPolicy.unsafeInterrupt()

        if !attentionForeground && AccessWindowBridge.isActive() && !AccessWindowBridge.isPendingReshield() {
            if unsafe {
                TestLogger.shared.log(
                    "ATTN-M10",
                    "unsafe_interrupt applying while Attention background label=\(label) access_window_end_at=\(endAt) reason=\(reason)"
                )
                performReshield(
                    apps: apps,
                    mode: .onWindowEnd,
                    reason: "unsafe_interrupt_timer",
                    mechanism: "unsafe_interrupt_while_tracked_may_be_foreground",
                    logTag: "ATTN-M10"
                )
                return
            }
            AccessWindowBridge.markPendingReshield()
            TestLogger.shared.log(
                "ATTN-M09",
                "window_end_while_foreground deferred=true label=\(label) access_window_end_at=\(endAt) reason=\(reason) — will re-shield when Attention active"
            )
            TestLogger.shared.log(
                "ATTN-P04",
                "window_end deferred=true label=\(label) access_window_end_at=\(endAt) reason=\(reason) mechanism=pending_until_attention_active — not session_end"
            )
            TestLogger.shared.log(
                "ATTN-M10",
                "deferred reshield_mode=on_window_end unsafe_interrupt=false reason=\(reason)"
            )
            refreshStatus()
            return
        }

        guard attentionForeground else {
            refreshStatus()
            return
        }

        let mechanism = reason == "timer_fired" ? "host_timer_attention_active" : "host_deferred_on_attention_active"
        performReshield(
            apps: apps,
            mode: .onWindowEnd,
            reason: mechanism,
            mechanism: mechanism,
            logTag: "ATTN-M10"
        )
    }

    private func consumePendingThresholdIfNeeded(reason: String, apps: [TrackedApp]) {
        guard ReshieldPolicy.mode() == .onThreshold else { return }
        guard ReshieldPolicy.isPendingThreshold() else { return }

        let pendingAt = ReshieldPolicy.suite?.string(forKey: ReshieldPolicy.pendingThresholdAtKey)

        if !attentionForeground {
            TestLogger.shared.log(
                "ATTN-M10",
                "threshold_pending waiting_host_active pending_at=\(pendingAt ?? "?") reason=\(reason)"
            )
            return
        }

        var delayNote = "n/a"
        if let pendingAt, let date = ISO8601DateFormatter().date(from: pendingAt) {
            delayNote = String(format: "%.2f", Date().timeIntervalSince(date))
        }

        performReshield(
            apps: apps,
            mode: .onThreshold,
            reason: "host_after_threshold delay_s=\(delayNote)",
            mechanism: "host_on_threshold",
            logTag: "ATTN-M10"
        )
    }

    private func performReshield(
        apps: [TrackedApp],
        mode: ReshieldMode,
        reason: String,
        mechanism: String,
        logTag: String
    ) {
        cancelTimer()
        let targetID = AccessWindowBridge.trackedId()
        var targets: [TrackedApp]
        if let targetID, let match = apps.first(where: { $0.id == targetID }) {
            targets = [match]
        } else if let match = apps.first(where: { $0.userLabel == AccessWindowBridge.label() }) {
            targets = [match]
        } else {
            targets = apps
        }

        // Threshold mode may target via pending labels if window already cleared.
        if targets.isEmpty || (mode == .onThreshold && AccessWindowBridge.trackedId() == nil) {
            let labels = ReshieldPolicy.suite?.string(forKey: ReshieldPolicy.pendingThresholdLabelsKey)?
                .split(separator: ",")
                .map(String.init) ?? []
            if let first = labels.first, let match = apps.first(where: { $0.userLabel == first }) {
                targets = [match]
            }
        }

        if targets.isEmpty {
            TestLogger.shared.log(
                logTag,
                "reshielded=false reshield_mode=\(mode.rawValue) reason=\(reason) detail=no_matching_tracked_app"
            )
            ReshieldPolicy.recordApplied(mode: mode, reason: "\(reason)_failed_no_app", fromExtension: false)
            refreshStatus()
            return
        }

        ShieldController.shared.addTokensToShield(apps: targets, logTag: logTag)
        ReshieldPolicy.recordApplied(
            mode: mode,
            reason: reason,
            fromExtension: false,
            appID: targets.first?.id,
            userLabel: targets.first?.userLabel
        )
        TestLogger.shared.log(
            logTag,
            "reshielded=true reshield_mode=\(mode.rawValue) reshield_applied_at=\(ReshieldPolicy.suite?.string(forKey: ReshieldPolicy.lastAppliedAtKey) ?? "?") reason=\(reason) mechanism=\(mechanism) labels=[\(targets.map(\.userLabel).joined(separator: ","))]"
        )
        // Keep M09-readable line too when window-driven.
        if mode == .onWindowEnd {
            TestLogger.shared.log(
                "ATTN-M09",
                "window_end reshielded=true mechanism=\(mechanism) labels=[\(targets.map(\.userLabel).joined(separator: ","))] access_window_end_at=\(AccessWindowBridge.suite?.string(forKey: AccessWindowBridge.endAtKey) ?? "?") — not session_end"
            )
            TestLogger.shared.log(
                "ATTN-P04",
                "window_end reshielded=true mechanism=\(mechanism) labels=[\(targets.map(\.userLabel).joined(separator: ","))] access_window_end_at=\(AccessWindowBridge.suite?.string(forKey: AccessWindowBridge.endAtKey) ?? "?") unit=access_window — not session_end"
            )
            // recordApplied already logged access_window_end for this app.
        }
        refreshStatus()
    }

    private func refreshStatus() {
        statusText = AccessWindowBridge.statusSummary()
        reshieldStatusText = ReshieldPolicy.statusSummary()
    }
}
