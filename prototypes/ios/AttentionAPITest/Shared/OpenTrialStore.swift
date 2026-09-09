import Foundation
import Combine

/// Ground-truth open trial counters for M08 (human taps). Not product opens.
@MainActor
final class OpenTrialStore: ObservableObject {
    static let shared = OpenTrialStore()

    private static let truthKey = "attention.m08.truth_count"
    private static let thresholdDetectKey = "attention.m08.threshold_detect_count"
    private static let notesKey = "attention.m08.trial_notes"

    @Published private(set) var truthCount: Int
    @Published private(set) var thresholdDetectCount: Int
    @Published var notes: String

    private init() {
        truthCount = ExperimentStore.shared.defaultsInt(Self.truthKey)
        thresholdDetectCount = ExperimentStore.shared.defaultsInt(Self.thresholdDetectKey)
        notes = ExperimentStore.shared.string(Self.notesKey) ?? ""
    }

    func bumpTruth() {
        truthCount += 1
        ExperimentStore.shared.setInt(truthCount, forKey: Self.truthKey)
        TestLogger.shared.log(
            "ATTN-M08",
            "truth_tap count=\(truthCount) rule=rule_cannot_see_launches (M07 is duration thresholds)"
        )
    }

    func bumpThresholdDetect(reason: String) {
        thresholdDetectCount += 1
        ExperimentStore.shared.setInt(thresholdDetectCount, forKey: Self.thresholdDetectKey)
        TestLogger.shared.log(
            "ATTN-M08",
            "threshold_event detect=\(thresholdDetectCount) truth=\(truthCount) reason=\(reason)"
        )
    }

    func reset() {
        truthCount = 0
        thresholdDetectCount = 0
        ExperimentStore.shared.setInt(0, forKey: Self.truthKey)
        ExperimentStore.shared.setInt(0, forKey: Self.thresholdDetectKey)
        TestLogger.shared.log("ATTN-M08", "trial_reset")
    }

    func persistNotes() {
        ExperimentStore.shared.setString(notes, forKey: Self.notesKey)
    }

    func summaryLine() -> String {
        let misses = max(0, truthCount - thresholdDetectCount)
        let falsePos = max(0, thresholdDetectCount - truthCount)
        return "truth=\(truthCount) threshold_detections=\(thresholdDetectCount) approx_misses=\(misses) approx_false_pos=\(falsePos) — NOT opens"
    }
}

extension ExperimentStore {
    func defaultsInt(_ key: String) -> Int {
        // ExperimentStore only exposes bool/string/data — use suite via ShieldCopySettings
        ShieldCopySettings.suite?.integer(forKey: key) ?? 0
    }

    func setInt(_ value: Int, forKey key: String) {
        ShieldCopySettings.suite?.set(value, forKey: key)
    }
}
