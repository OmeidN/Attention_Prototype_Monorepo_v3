import Foundation
import FamilyControls
import ManagedSettings

/// App Group keys shared by the host app and Shield Configuration extension (M05+).
enum ShieldCopySettings {
    static let appGroupID = ExperimentStore.appGroupID
    static let variantKey = "shield_copy_variant"
    static let trackedAppsKey = "attention.m03.tracked_apps"

    static var suite: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// A or B — written by Experiments, read by the shield configuration extension.
    static func readVariant() -> String? {
        suite?.string(forKey: variantKey)
    }

    static func writeVariant(_ variant: String) {
        suite?.set(variant, forKey: variantKey)
    }

    static func userLabel(for token: ApplicationToken?) -> String? {
        guard let token,
              let data = suite?.data(forKey: trackedAppsKey),
              let apps = try? JSONDecoder().decode([TrackedApp].self, from: data)
        else { return nil }
        return apps.first(where: { $0.token == token })?.userLabel
    }
}
