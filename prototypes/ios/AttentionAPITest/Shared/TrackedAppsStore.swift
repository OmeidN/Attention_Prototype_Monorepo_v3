import Foundation
import Combine
import FamilyControls
import ManagedSettings

/// Owns the UUID-keyed tracked-app list and last picker counts.
///
/// Storage is App Group `UserDefaults` via `ExperimentStore`. Dictionaries are
/// never keyed by `ApplicationToken`.
///
/// **Add model (post-M03 UX):** one new app at a time. Existing rows keep their
/// UUID/label; only the newly picked token is named and appended.
@MainActor
final class TrackedAppsStore: ObservableObject {
    static let shared = TrackedAppsStore()

    private static let appsKey = "attention.m03.tracked_apps"
    private static let selectionKey = "attention.m03.last_selection"

    @Published private(set) var apps: [TrackedApp] = []
    @Published var lastSelection = FamilyActivitySelection()

    var applicationCount: Int { apps.count }
    var categoryCount: Int { lastSelection.categoryTokens.count }
    var webDomainCount: Int { lastSelection.webDomainTokens.count }
    var userLabels: [String] { apps.map(\.userLabel) }
    var trackedTokens: Set<ApplicationToken> { Set(apps.map(\.token)) }

    private init() {
        load()
    }

    // MARK: - Persistence

    func load() {
        if let data = ExperimentStore.shared.data(forKey: Self.appsKey),
           let decoded = try? JSONDecoder().decode([TrackedApp].self, from: data) {
            apps = decoded
        } else {
            apps = []
        }

        if let data = ExperimentStore.shared.data(forKey: Self.selectionKey),
           let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            lastSelection = decoded
        } else {
            lastSelection = selectionFromTrackedApps()
        }
    }

    private func persistApps() {
        guard let data = try? JSONEncoder().encode(apps) else { return }
        ExperimentStore.shared.setData(data, forKey: Self.appsKey)
    }

    private func persistSelection() {
        guard let data = try? JSONEncoder().encode(lastSelection) else { return }
        ExperimentStore.shared.setData(data, forKey: Self.selectionKey)
    }

    /// Rebuild picker selection from persisted tracked tokens (stable source of truth).
    func selectionFromTrackedApps() -> FamilyActivitySelection {
        var selection = FamilyActivitySelection()
        selection.applicationTokens = trackedTokens
        return selection
    }

    func syncSelectionFromTrackedApps() {
        lastSelection = selectionFromTrackedApps()
        persistSelection()
    }

    // MARK: - Mutations

    /// Append one newly named app. Existing UUIDs/labels are untouched.
    @discardableResult
    func addTrackedApp(label: String, token: ApplicationToken) -> TrackedApp {
        let duration = AccessWindowBridge.preferredDurationSeconds()
        let app = TrackedApp(
            id: UUID(),
            userLabel: label,
            token: token,
            dateAdded: Date(),
            windowDurationSeconds: duration
        )
        apps.append(app)
        persistApps()
        syncSelectionFromTrackedApps()
        logSelectionChanged(reason: "added_one")
        TestLogger.shared.log(
            "ATTN-P01",
            "app_added id=\(app.id.uuidString) label=\(label) total=\(apps.count) window_s=\(duration)"
        )
        return app
    }

    func setWindowDuration(appID: UUID, seconds: Int) {
        guard let index = apps.firstIndex(where: { $0.id == appID }) else { return }
        let clamped = max(15, seconds)
        apps[index].windowDurationSeconds = clamped
        persistApps()
        TestLogger.shared.log(
            "ATTN-P05A",
            "window_duration_set id=\(appID.uuidString) label=\(apps[index].userLabel) seconds=\(clamped)"
        )
    }

    func updateLastSelection(_ selection: FamilyActivitySelection) {
        lastSelection = selection
        persistSelection()
    }

    func clearAll() {
        apps = []
        lastSelection = FamilyActivitySelection()
        ExperimentStore.shared.removeObject(forKey: Self.appsKey)
        ExperimentStore.shared.removeObject(forKey: Self.selectionKey)
        TestLogger.shared.log("ATTN-M03", "selection_cleared")
        TestLogger.shared.log("ATTN-P01", "selection_cleared remaining=0")
    }

    /// Re-bind a live token onto an existing UUID after a fresh picker session.
    @discardableResult
    func refreshToken(for id: UUID, newToken: ApplicationToken) -> Bool {
        guard let index = apps.firstIndex(where: { $0.id == id }) else {
            TestLogger.shared.log("ATTN-M03", "token_refresh_failed reason=unknown_id id=\(id.uuidString)")
            TestLogger.shared.log("ATTN-P01", "token_refresh_failed reason=unknown_id id=\(id.uuidString)")
            return false
        }
        apps[index].token = newToken
        persistApps()
        syncSelectionFromTrackedApps()
        TestLogger.shared.log(
            "ATTN-M03",
            "token_refreshed id=\(id.uuidString) label=\(apps[index].userLabel)"
        )
        TestLogger.shared.log(
            "ATTN-P01",
            "token_refreshed id=\(id.uuidString) label=\(apps[index].userLabel) via=picker_rebind"
        )
        return true
    }

    /// Best-effort `ManagedSettingsStore.refresh` (iOS 26.5+). On failure, use picker re-bind.
    @discardableResult
    func attemptSystemTokenRefresh(for id: UUID) -> Bool {
        guard let index = apps.firstIndex(where: { $0.id == id }) else {
            TestLogger.shared.log("ATTN-P01", "system_token_refresh_failed reason=unknown_id")
            return false
        }
        let label = apps[index].userLabel
        guard #available(iOS 26.5, *) else {
            TestLogger.shared.log(
                "ATTN-P01",
                "system_token_refresh_unavailable id=\(id.uuidString) label=\(label) — use Re-bind"
            )
            return false
        }
        var tokens = [apps[index].token]
        do {
            try ManagedSettingsStore.refresh(&tokens)
            guard let refreshed = tokens.first else {
                TestLogger.shared.log(
                    "ATTN-P01",
                    "system_token_refresh_failed id=\(id.uuidString) label=\(label) reason=empty_result — use Re-bind"
                )
                return false
            }
            apps[index].token = refreshed
            persistApps()
            syncSelectionFromTrackedApps()
            TestLogger.shared.log(
                "ATTN-P01",
                "token_refreshed id=\(id.uuidString) label=\(label) via=ManagedSettingsStore.refresh"
            )
            return true
        } catch {
            TestLogger.shared.log(
                "ATTN-P01",
                "system_token_refresh_failed id=\(id.uuidString) label=\(label) error=\(error.localizedDescription) — use Re-bind"
            )
            return false
        }
    }

    func app(id: UUID) -> TrackedApp? {
        apps.first { $0.id == id }
    }

    /// Tokens in `selection` that are not already tracked.
    func newTokens(in selection: FamilyActivitySelection) -> [ApplicationToken] {
        Array(selection.applicationTokens.subtracting(trackedTokens))
    }

    /// Already-tracked tokens the user unchecked in the system picker.
    func removedTrackedTokens(in selection: FamilyActivitySelection) -> [ApplicationToken] {
        Array(trackedTokens.subtracting(selection.applicationTokens))
    }

    /// Labels for tokens that disappeared from a picker selection (best-effort match).
    func labels(forTokens tokens: [ApplicationToken]) -> [String] {
        tokens.compactMap { token in
            apps.first(where: { $0.token == token })?.userLabel
        }
    }

    /// Remove by stable UUID. Does not require the system picker.
    func removeApps(ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        let before = apps.count
        let removedLabels = apps.filter { ids.contains($0.id) }.map(\.userLabel)
        apps.removeAll { ids.contains($0.id) }
        persistApps()
        syncSelectionFromTrackedApps()
        let labels = userLabels.joined(separator: ",")
        TestLogger.shared.log(
            "ATTN-M03",
            "apps_removed count=\(before - apps.count) remaining=\(apps.count) labels=[\(labels)]"
        )
        TestLogger.shared.log(
            "ATTN-P01",
            "apps_removed count=\(before - apps.count) removed=[\(removedLabels.joined(separator: ","))] remaining=\(apps.count)"
        )
    }

    private func logSelectionChanged(reason: String) {
        let labels = userLabels.joined(separator: ",")
        TestLogger.shared.log(
            "ATTN-M03",
            "selection_changed reason=\(reason) apps=\(applicationCount) categories=\(categoryCount) webDomains=\(webDomainCount) labels=[\(labels)]"
        )
        TestLogger.shared.log(
            "ATTN-P01",
            "selection_changed reason=\(reason) apps=\(applicationCount) labels=[\(labels)]"
        )
    }
}
