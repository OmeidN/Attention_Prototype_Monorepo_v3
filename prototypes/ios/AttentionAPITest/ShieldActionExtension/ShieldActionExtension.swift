import ManagedSettings
import DeviceActivity
import Foundation

/// P05B: Never Mind / Continue. Continue arms wall-clock re-shield only (works if Attention is dead).
final class ShieldActionExtension: ShieldActionDelegate {
    private let store = ManagedSettingsStore()

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            let event = ShieldActionBridge.record(action: "intentional_choice", token: application)
            _ = InterventionState.recordNeverMind(appID: event.trackedAppId)
            ShieldActionBridge.writeExtensionNote(
                "ATTN-P03 never_mind label=\(event.userLabel ?? "NO_LABEL") id=\(event.trackedAppId?.uuidString ?? "nil")"
            )
            completionHandler(.close)

        case .secondaryButtonPressed:
            let event = ShieldActionBridge.record(action: "continue", token: application)
            let (prev, next, count) = InterventionState.recordContinue(appID: event.trackedAppId)
            ShieldCopySettings.suite?.set(
                "prev_level=\(prev) next_level=\(next) continues=\(count) label=\(event.userLabel ?? "NO_LABEL")",
                forKey: "attention.m11.last_continue_transition"
            )

            // Wall-only closer (usage threshold off).
            ReshieldPolicy.setMode(.onThreshold)
            let apps = Self.loadTrackedApps()
            let matched = apps.first(where: { $0.id == event.trackedAppId })
                ?? apps.first(where: { $0.token == application })
            let duration = matched?.windowDurationSeconds ?? AccessWindowBridge.preferredDurationSeconds()

            unblock(application)
            AccessWindowBridge.beginWindow(
                trackedAppId: event.trackedAppId,
                userLabel: event.userLabel,
                durationSeconds: duration
            )

            _ = HardWindowMonitor.rearm(apps: [], reason: "continue")
            var wallNote = "wall_skipped"
            if let matched {
                if let wallErr = HardWindowMonitor.armWallClock(for: matched, reason: "continue") {
                    wallNote = "wall_error=\(wallErr)"
                } else {
                    let wall = HardWindowMonitor.wallClockSeconds(forUsageWindowSeconds: duration)
                    wallNote = "wall_ok=\(wall)s"
                }
            }
            ShieldActionBridge.writeExtensionNote(
                "ATTN-P05B continue+wall_only label=\(event.userLabel ?? "NO_LABEL") id=\(event.trackedAppId?.uuidString ?? "nil") window_s=\(duration) \(wallNote)"
            )
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(.close)
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(.close)
    }

    private func unblock(_ token: ApplicationToken) {
        var applications = store.shield.applications ?? Set()
        applications.remove(token)
        store.shield.applications = applications.isEmpty ? nil : applications

        if applications.isEmpty {
            ShieldCopySettings.suite?.set(false, forKey: "attention.m04.last_shield_write_active")
        }
    }

    private static func loadTrackedApps() -> [TrackedApp] {
        guard let data = ShieldCopySettings.suite?.data(forKey: ShieldCopySettings.trackedAppsKey),
              let apps = try? JSONDecoder().decode([TrackedApp].self, from: data)
        else { return [] }
        return apps
    }
}
