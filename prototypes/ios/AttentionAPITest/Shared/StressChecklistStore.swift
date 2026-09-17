import Foundation
import Combine

/// Human-ticked stress matrix for M12. Persisted in App Group; no new Screen Time APIs.
struct StressCheckItem: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    var done: Bool
    var result: String
    var notes: String
}

@MainActor
final class StressChecklistStore: ObservableObject {
    static let shared = StressChecklistStore()

    private static let storageKey = "attention.m12.stress_checklist"
    private static let reliabilityKey = "attention.m12.full_day_reliability_note"

    @Published private(set) var items: [StressCheckItem]
    @Published var fullDayReliabilityNote: String

    private init() {
        if let data = ShieldCopySettings.suite?.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([StressCheckItem].self, from: data),
           !decoded.isEmpty {
            items = decoded
        } else {
            items = Self.defaultItems()
        }
        fullDayReliabilityNote = ShieldCopySettings.suite?.string(forKey: Self.reliabilityKey) ?? ""
    }

    static func defaultItems() -> [StressCheckItem] {
        [
            StressCheckItem(id: "force_quit", title: "Force quit Attention — shielded app still shielded?", done: false, result: "", notes: ""),
            StressCheckItem(id: "reboot", title: "Reboot — shield persists? labels OK? monitor?", done: false, result: "", notes: ""),
            StressCheckItem(id: "lock_unlock", title: "Lock/unlock during shield + during Continue window", done: false, result: "", notes: ""),
            StressCheckItem(id: "rapid_reopen", title: "Rapid reopen selected app ~20×", done: false, result: "", notes: ""),
            StressCheckItem(id: "app_switcher", title: "App switcher bypass?", done: false, result: "", notes: ""),
            StressCheckItem(id: "notification", title: "Notification / deep link into selected app", done: false, result: "", notes: ""),
            StressCheckItem(id: "airplane", title: "Airplane mode — shield still applies", done: false, result: "", notes: ""),
            StressCheckItem(id: "date_rollover", title: "Date rollover (change date, restore) — M11 counts reset?", done: false, result: "", notes: ""),
            StressCheckItem(id: "revoke_auth", title: "Revoke Screen Time / Family Controls — no crash", done: false, result: "", notes: ""),
            StressCheckItem(id: "full_day", title: "Full day reliability (morning/mid/night)", done: false, result: "", notes: ""),
        ]
    }

    func setDone(id: String, done: Bool) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].done = done
        persist()
        TestLogger.shared.log("ATTN-M12", "checklist id=\(id) done=\(done) result=\(items[i].result)")
    }

    func setResult(id: String, result: String) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].result = result
        persist()
    }

    func setNotes(id: String, notes: String) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].notes = notes
        persist()
    }

    func setFullDayNote(_ note: String) {
        fullDayReliabilityNote = note
        ShieldCopySettings.suite?.set(note, forKey: Self.reliabilityKey)
        TestLogger.shared.log("ATTN-M12", "full_day_reliability \(note)")
    }

    func resetChecklist() {
        items = Self.defaultItems()
        persist()
        TestLogger.shared.log("ATTN-M12", "checklist_reset")
    }

    func summaryLine() -> String {
        let done = items.filter(\.done).count
        return "stress_checklist \(done)/\(items.count) ticked — export Logs after failures"
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            ShieldCopySettings.suite?.set(data, forKey: Self.storageKey)
        }
    }
}
