import Foundation
import Combine

/// P08: user settings (App Group). Global Continue budget; default window; Pause Attention.
@MainActor
final class AttentionSettingsStore: ObservableObject {
    static let shared = AttentionSettingsStore()

    static let continueBudgetKey = "attention.p08.continue_budget"
    static let pausedKey = "attention.p08.attention_paused"
    static let pausedAtKey = "attention.p08.paused_at"
    static let usageCheckpointStubKey = "attention.p08.usage_checkpoint_enabled"
    static let lastPauseNoteKey = "attention.p08.last_pause_note"

    static let budgetChoices = [3, 4, 5, 8, 10]
    static let defaultBudget = 5

    @Published var continueBudget: Int
    @Published var defaultWindowSeconds: Int
    @Published var attentionPaused: Bool
    @Published var usageCheckpointEnabled: Bool

    private var suite: UserDefaults? { ShieldCopySettings.suite }

    private init() {
        let defaults = ShieldCopySettings.suite
        let storedBudget = defaults?.object(forKey: Self.continueBudgetKey) as? Int
        continueBudget = storedBudget ?? Self.defaultBudget
        defaultWindowSeconds = AccessWindowBridge.preferredDurationSeconds()
        attentionPaused = defaults?.bool(forKey: Self.pausedKey) == true
        usageCheckpointEnabled = defaults?.bool(forKey: Self.usageCheckpointStubKey) == true
    }

    func reload() {
        continueBudget = suite?.object(forKey: Self.continueBudgetKey) as? Int ?? Self.defaultBudget
        defaultWindowSeconds = AccessWindowBridge.preferredDurationSeconds()
        attentionPaused = suite?.bool(forKey: Self.pausedKey) == true
        usageCheckpointEnabled = suite?.bool(forKey: Self.usageCheckpointStubKey) == true
    }

    func setContinueBudget(_ value: Int) {
        let clamped = max(1, min(20, value))
        continueBudget = clamped
        suite?.set(clamped, forKey: Self.continueBudgetKey)
        TestLogger.shared.log("ATTN-P08", "continue_budget_set \(clamped) (global)")
    }

    /// Updates preferred duration + all tracked apps so next Continue uses the new length.
    func setDefaultWindowSeconds(_ seconds: Int, applyToTrackedApps: Bool = true) {
        AccessWindowBridge.setPreferredDurationSeconds(seconds)
        defaultWindowSeconds = seconds
        AccessWindowController.shared.durationSeconds = seconds
        if applyToTrackedApps {
            let store = TrackedAppsStore.shared
            for app in store.apps {
                store.setWindowDuration(appID: app.id, seconds: seconds)
            }
            _ = HardWindowMonitor.rearm(apps: store.apps, reason: "settings_window_change")
        }
        TestLogger.shared.log("ATTN-P08", "default_window_s=\(seconds) applied_to_tracked=\(applyToTrackedApps)")
    }

    func setUsageCheckpointEnabled(_ on: Bool) {
        usageCheckpointEnabled = on
        suite?.set(on, forKey: Self.usageCheckpointStubKey)
        TestLogger.shared.log("ATTN-P08", "usage_checkpoint_stub enabled=\(on) (wired in P10)")
    }

    func continuesRemaining(continuesToday: Int) -> Int {
        max(0, continueBudget - continuesToday)
    }

    func markPaused() {
        attentionPaused = true
        suite?.set(true, forKey: Self.pausedKey)
        let at = TestLogger.isoString(Date())
        suite?.set(at, forKey: Self.pausedAtKey)
        let note = "attention_paused at=\(at)"
        suite?.set(note, forKey: Self.lastPauseNoteKey)
        TestLogger.shared.log("ATTN-P08", note)
    }

    func markResumed() {
        attentionPaused = false
        suite?.set(false, forKey: Self.pausedKey)
        let note = "attention_resumed at=\(TestLogger.isoString(Date()))"
        suite?.set(note, forKey: Self.lastPauseNoteKey)
        TestLogger.shared.log("ATTN-P08", note)
    }
}
