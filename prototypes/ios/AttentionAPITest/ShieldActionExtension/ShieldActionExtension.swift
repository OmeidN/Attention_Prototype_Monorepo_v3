import ManagedSettings
import DeviceActivity
import Foundation

/// P05A: Never Mind / Continue. Continue arms hard usage-threshold re-shield (works if Attention is dead).
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

            // Set-and-forget closer: re-arm thresholds so monitor extension can hard-re-shield.
            ReshieldPolicy.setMode(.onThreshold)
            let armError = HardWindowMonitor.rearm(apps: apps, reason: "continue")
            let armNote = armError.map { "arm_error=\($0)" } ?? "arm_ok"
            ShieldActionBridge.writeExtensionNote(
                "ATTN-P05A continue+hard_window label=\(event.userLabel ?? "NO_LABEL") id=\(event.trackedAppId?.uuidString ?? "nil") duration_s=\(duration) \(armNote) — usage_duration may yank"
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
