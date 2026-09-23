import Foundation
import Combine

/// P09: first-launch gate. Returning installs skip to Home when `isComplete`.
@MainActor
final class OnboardingStore: ObservableObject {
    static let shared = OnboardingStore()

    static let completeKey = "attention.p09.onboarding_complete"
    static let completedAtKey = "attention.p09.completed_at"
    static let lastStepKey = "attention.p09.last_step"
    static let lastFinishKey = "attention.p09.last_finish_note"

    @Published private(set) var isComplete: Bool
    @Published private(set) var lastStep: String
    @Published var showTipsReplay = false

    private var suite: UserDefaults? { ShieldCopySettings.suite }

    private init() {
        isComplete = ShieldCopySettings.suite?.bool(forKey: Self.completeKey) == true
        lastStep = ShieldCopySettings.suite?.string(forKey: Self.lastStepKey) ?? "none"
    }

    func reload() {
        isComplete = suite?.bool(forKey: Self.completeKey) == true
        lastStep = suite?.string(forKey: Self.lastStepKey) ?? "none"
    }

    func markStep(_ step: String) {
        lastStep = step
        suite?.set(step, forKey: Self.lastStepKey)
        TestLogger.shared.log("ATTN-P09", "step_complete \(step)")
    }

    func markComplete(shieldsApplied: Bool) {
        isComplete = true
        showTipsReplay = false
        let at = TestLogger.isoString(Date())
        suite?.set(true, forKey: Self.completeKey)
        suite?.set(at, forKey: Self.completedAtKey)
        let note = "onboarding_complete shields_applied=\(shieldsApplied) at=\(at)"
        suite?.set(note, forKey: Self.lastFinishKey)
        TestLogger.shared.log("ATTN-P09", note)
    }

    func requestTipsReplay() {
        showTipsReplay = true
        TestLogger.shared.log("ATTN-P09", "tips_replay_opened")
    }

    func resetFirstLaunch() {
        isComplete = false
        showTipsReplay = false
        lastStep = "none"
        suite?.set(false, forKey: Self.completeKey)
        suite?.removeObject(forKey: Self.completedAtKey)
        suite?.set("none", forKey: Self.lastStepKey)
        TestLogger.shared.log("ATTN-P09", "first_launch_reset")
    }
}
