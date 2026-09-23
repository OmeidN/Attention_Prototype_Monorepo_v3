import Foundation
import Combine

/// P11 human-ticked stress matrix. Separate from the lab M12 checklist. No new Screen Time APIs.
struct DogfoodCheckItem: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    var done: Bool
    var result: String
    var notes: String
}

@MainActor
final class DogfoodChecklistStore: ObservableObject {
    static let shared = DogfoodChecklistStore()

    private static let storageKey = "attention.p11.dogfood_checklist"
    private static let allDayKey = "attention.p11.all_day_note"

    @Published private(set) var items: [DogfoodCheckItem]
    @Published var allDayNote: String

    private init() {
        if let data = ShieldCopySettings.suite?.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([DogfoodCheckItem].self, from: data),
           !decoded.isEmpty {
            items = decoded
        } else {
            items = Self.defaultItems()
        }
        allDayNote = ShieldCopySettings.suite?.string(forKey: Self.allDayKey) ?? ""
    }

    static func defaultItems() -> [DogfoodCheckItem] {
        [
            DogfoodCheckItem(id: "force_quit", title: "Force quit Attention — tracked apps still shielded", done: false, result: "", notes: ""),
            DogfoodCheckItem(id: "reboot", title: "Reboot — shields + labels correct", done: false, result: "", notes: ""),
            DogfoodCheckItem(id: "lock_unlock", title: "Lock/unlock during shield and during a Continue window", done: false, result: "", notes: ""),
            DogfoodCheckItem(id: "rapid_reopen", title: "Rapid reopen a tracked app ~20×", done: false, result: "", notes: ""),
            DogfoodCheckItem(id: "app_switcher", title: "App switcher — no unexpected bypass", done: false, result: "", notes: ""),
            DogfoodCheckItem(id: "notifications", title: "Notifications quieter while shielded; after Continue matches honesty copy", done: false, result: "", notes: ""),
            DogfoodCheckItem(id: "airplane", title: "Airplane mode — shield still applies", done: false, result: "", notes: ""),
            DogfoodCheckItem(id: "date_rollover", title: "Date rollover — Continues / budget display reset (history kept)", done: false, result: "", notes: ""),
            DogfoodCheckItem(id: "revoke_auth", title: "Revoke Family Controls — no crash; re-authorize CTA", done: false, result: "", notes: ""),
            DogfoodCheckItem(id: "all_day", title: "All-day dogfood — morning / midday / evening", done: false, result: "", notes: ""),
        ]
    }

    func setDone(id: String, done: Bool) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].done = done
        persist()
        TestLogger.shared.log("ATTN-P11", "checklist id=\(id) done=\(done) result=\(items[i].result)")
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

    func setAllDayNote(_ note: String) {
        allDayNote = note
        ShieldCopySettings.suite?.set(note, forKey: Self.allDayKey)
    }

    func resetChecklist() {
        items = Self.defaultItems()
        allDayNote = ""
        ShieldCopySettings.suite?.removeObject(forKey: Self.allDayKey)
        persist()
        TestLogger.shared.log("ATTN-P11", "checklist_reset")
    }

    func summaryLine() -> String {
        let done = items.filter(\.done).count
        return "dogfood_checklist \(done)/\(items.count) ticked"
    }

    func exportBlock() -> String {
        var lines = ["P11 dogfood checklist", summaryLine()]
        for item in items {
            lines.append("[\(item.done ? "x" : " ")] \(item.id) result=\(item.result.isEmpty ? "?" : item.result) \(item.title)")
            if !item.notes.isEmpty {
                lines.append("    notes=\(item.notes)")
            }
        }
        if !allDayNote.isEmpty {
            lines.append("all_day=\(allDayNote)")
        }
        return lines.joined(separator: "\n")
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            ShieldCopySettings.suite?.set(data, forKey: Self.storageKey)
        }
    }
}
