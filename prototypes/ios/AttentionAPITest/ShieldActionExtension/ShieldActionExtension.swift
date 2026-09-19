import ManagedSettings

/// P03: primary = Never Mind (stay blocked), secondary = Continue (lift shield + start access_window for P04).
/// Mapping matches ShieldConfigurationExtension button labels.
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
            unblock(application)
            AccessWindowBridge.beginWindow(trackedAppId: event.trackedAppId, userLabel: event.userLabel)
            ShieldActionBridge.writeExtensionNote(
                "ATTN-P04 continue+window label=\(event.userLabel ?? "NO_LABEL") id=\(event.trackedAppId?.uuidString ?? "nil") duration_s=\(AccessWindowBridge.preferredDurationSeconds()) end=\(AccessWindowBridge.suite?.string(forKey: AccessWindowBridge.endAtKey) ?? "?")"
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
}
