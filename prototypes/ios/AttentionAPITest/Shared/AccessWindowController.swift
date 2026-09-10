import Foundation
import Combine
import ManagedSettings

/// Host-side access window timer + deferred re-shield (M09).
/// Does not yank mid-use: if Attention is background at end, defer until Attention is active again.
@MainActor
final class AccessWindowController: ObservableObject {
    static let shared = AccessWindowController()

    @Published var durationSeconds: Int
    @Published var honestUnit: String
    @Published private(set) var statusText: String
    @Published private(set) var ruleText =
        "Rule: at window end do NOT tear down mid-scroll. If Attention is background, defer re-shield until Attention is active (M10 owns interrupt policy)."

    private var timer: Timer?
    private var attentionForeground = true

    private init() {
        durationSeconds = AccessWindowBridge.preferredDurationSeconds()
        honestUnit = AccessWindowBridge.honestUnit()
        statusText = AccessWindowBridge.statusSummary()
    }

    func setDurationSeconds(_ seconds: Int) {
        durationSeconds = seconds
        AccessWindowBridge.setPreferredDurationSeconds(seconds)
        TestLogger.shared.log("ATTN-M09", "preferred_duration_s=\(seconds)")
        refreshStatus()
    }

    func setHonestUnit(_ unit: String) {
        honestUnit = unit
        AccessWindowBridge.setHonestUnit(unit)
        TestLogger.shared.log("ATTN-M09", "honest_unit_choice=\(unit)")
    }

    func sync(reason: String, attentionForeground: Bool, apps: [TrackedApp]) {
        self.attentionForeground = attentionForeground
        logWindowStartIfNeeded(reason: reason)
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

        if !attentionForeground && AccessWindowBridge.isActive() && !AccessWindowBridge.isPendingReshield() {
            AccessWindowBridge.markPendingReshield()
            TestLogger.shared.log(
                "ATTN-M09",
                "window_end_while_foreground deferred=true label=\(label) access_window_end_at=\(endAt) reason=\(reason) — will re-shield when Attention active"
            )
            refreshStatus()
            return
        }

        guard attentionForeground else {
            refreshStatus()
            return
        }

        performReshield(apps: apps, mechanism: reason == "timer_fired" ? "host_timer_attention_active" : "host_deferred_on_attention_active")
    }

    private func performReshield(apps: [TrackedApp], mechanism: String) {
        cancelTimer()
        let targetID = AccessWindowBridge.trackedId()
        let targets: [TrackedApp]
        if let targetID, let match = apps.first(where: { $0.id == targetID }) {
            targets = [match]
        } else if let match = apps.first(where: { $0.userLabel == AccessWindowBridge.label() }) {
            targets = [match]
        } else {
            targets = apps
        }

        if targets.isEmpty {
            TestLogger.shared.log(
                "ATTN-M09",
                "window_end reshielded=false mechanism=\(mechanism) reason=no_matching_tracked_app label=\(AccessWindowBridge.label())"
            )
            AccessWindowBridge.markReshielded(mechanism: "\(mechanism)_failed_no_app")
            refreshStatus()
            return
        }

        ShieldController.shared.addTokensToShield(apps: targets, logTag: "ATTN-M09")
        AccessWindowBridge.markReshielded(mechanism: mechanism)
        TestLogger.shared.log(
            "ATTN-M09",
            "window_end reshielded=true mechanism=\(mechanism) labels=[\(targets.map(\.userLabel).joined(separator: ","))] access_window_end_at=\(AccessWindowBridge.suite?.string(forKey: AccessWindowBridge.endAtKey) ?? "?") — not session_end"
        )
        refreshStatus()
    }

    private func refreshStatus() {
        statusText = AccessWindowBridge.statusSummary()
    }
}
