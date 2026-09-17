import Foundation
import FamilyControls
import ManagedSettings

/// Manual apply/clear of ManagedSettings shields for tracked apps.
/// M05 adds ShieldConfigurationExtension for custom chrome; actions remain M06.
@MainActor
final class ShieldController: ObservableObject {
    static let shared = ShieldController()

    private static let shieldedKey = "attention.m04.last_shield_write_active"
    private static let labelsKey = "attention.m04.last_shield_write_labels"
    private static let atKey = "attention.m04.last_shield_write_at"

    private let store = ManagedSettingsStore()

    /// Last successful write from this app — not an OS readback of shield state.
    @Published private(set) var lastWriteActive: Bool
    @Published private(set) var lastWriteLabels: String
    @Published private(set) var lastWriteAt: String?

    var statusLine: String {
        if lastWriteActive {
            let when = lastWriteAt ?? "?"
            return "shielded: yes (last write \(when)) — \(lastWriteLabels)"
        }
        if let when = lastWriteAt {
            return "shielded: no (last clear \(when))"
        }
        return "shielded: no (no write yet this install)"
    }

    private init() {
        lastWriteActive = ExperimentStore.shared.bool(Self.shieldedKey)
        lastWriteLabels = ExperimentStore.shared.string(Self.labelsKey) ?? ""
        lastWriteAt = ExperimentStore.shared.string(Self.atKey)
    }

    /// Apply default system shield to current live tokens from tracked apps.
    func shieldSelected(apps: [TrackedApp]) {
        let tokens = Set(apps.map(\.token))
        let labels = apps.map(\.userLabel)
        let ids = apps.map { $0.id.uuidString }

        store.shield.applications = tokens.isEmpty ? nil : tokens

        lastWriteActive = !tokens.isEmpty
        lastWriteLabels = labels.joined(separator: ", ")
        lastWriteAt = TestLogger.isoString(Date())
        persistWriteState()

        TestLogger.shared.log(
            "ATTN-M04",
            "shield_apply count=\(tokens.count) labels=[\(lastWriteLabels)] ids=[\(ids.joined(separator: ","))]"
        )
    }

    func clearShield() {
        store.shield.applications = nil
        lastWriteActive = false
        lastWriteLabels = ""
        lastWriteAt = TestLogger.isoString(Date())
        persistWriteState()
        TestLogger.shared.log("ATTN-M04", "shield_clear")
    }

    /// Clear "we think we are shielding" UI when auth is lost (M12). Does not crash.
    func markAuthLostUI() {
        lastWriteActive = false
        lastWriteLabels = ""
        lastWriteAt = TestLogger.isoString(Date())
        persistWriteState()
    }

    /// Union tokens into the current shield set (M09 access-window end / partial re-shield).
    func addTokensToShield(apps: [TrackedApp], logTag: String = "ATTN-M04") {
        guard !apps.isEmpty else { return }
        var applications = store.shield.applications ?? Set()
        for app in apps {
            applications.insert(app.token)
        }
        store.shield.applications = applications

        lastWriteActive = true
        lastWriteLabels = apps.map(\.userLabel).joined(separator: ", ")
        lastWriteAt = TestLogger.isoString(Date())
        persistWriteState()

        let ids = apps.map { $0.id.uuidString }.joined(separator: ",")
        TestLogger.shared.log(
            logTag,
            "shield_add count=\(apps.count) labels=[\(lastWriteLabels)] ids=[\(ids)]"
        )
    }

    private func persistWriteState() {
        ExperimentStore.shared.setBool(lastWriteActive, forKey: Self.shieldedKey)
        ExperimentStore.shared.setString(lastWriteLabels, forKey: Self.labelsKey)
        if let lastWriteAt {
            ExperimentStore.shared.setString(lastWriteAt, forKey: Self.atKey)
        }
    }
}
