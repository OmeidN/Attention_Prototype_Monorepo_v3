import ManagedSettings

/// M06: primary = Never Mind (stay blocked), secondary = Continue (lift shield for that app).
/// Mapping matches ShieldConfigurationExtension button labels from M05.
final class ShieldActionExtension: ShieldActionDelegate {
    private let store = ManagedSettingsStore()

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            _ = ShieldActionBridge.record(action: "never_mind", token: application)
            completionHandler(.close)

        case .secondaryButtonPressed:
            _ = ShieldActionBridge.record(action: "continue", token: application)
            unblock(application)
            // `.close` dismisses the shield UI; do not re-apply here (M10 owns re-shield policy).
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
