import ManagedSettings
import ManagedSettingsUI
import UIKit

/// P05 product friction ladder: L0→L2 copy from per-app `continues_today` (App Group).
/// Tone/stakes only — no Continue-button delay API.
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfiguration(token: application.token)
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration(token: application.token)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration(token: nil)
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration(token: nil)
    }

    private func makeConfiguration(token: ApplicationToken?) -> ShieldConfiguration {
        let rolled = InterventionState.ensureToday()
        if rolled {
            // Extension cannot use TestLogger; host logs day_rollover on next active.
            ShieldCopySettings.suite?.set(
                "day_rollover local_day=\(InterventionState.todayString())",
                forKey: "attention.p05.last_day_rollover_note"
            )
        }

        let label = ShieldCopySettings.userLabel(for: token) ?? "app"
        let titleText = "Attention — \(label)"

        guard ShieldCopySettings.suite != nil else {
            return ShieldConfiguration(
                backgroundBlurStyle: .systemMaterial,
                backgroundColor: UIColor(white: 0.12, alpha: 1),
                icon: UIImage(systemName: "pause.circle"),
                title: ShieldConfiguration.Label(text: titleText, color: .white),
                subtitle: ShieldConfiguration.Label(
                    text: "Pause. Shared state unavailable — one static shield.",
                    color: UIColor(white: 0.85, alpha: 1)
                ),
                primaryButtonLabel: ShieldConfiguration.Label(text: "Never Mind", color: .white),
                primaryButtonBackgroundColor: UIColor(red: 0.2, green: 0.45, blue: 0.85, alpha: 1),
                secondaryButtonLabel: ShieldConfiguration.Label(text: "Continue", color: .white)
            )
        }

        let subtitleText: String
        let iconName: String
        let secondaryLabel: String
        let background: UIColor

        if let appID = resolvedAppID(token: token) {
            let continues = InterventionState.continueCount(appID: appID)
            let level = InterventionState.level(forContinueCount: continues)
            InterventionState.markLevelShown(level: level, label: label)
            ShieldCopySettings.suite?.set(
                "L\(level) continues_today=\(continues) label=\(label) id=\(appID.uuidString)",
                forKey: "attention.p05.last_level_config"
            )

            switch level {
            case 0:
                subtitleText = "Pause a beat. What did you come here for?"
                iconName = "pause.circle"
                secondaryLabel = "Continue"
                background = UIColor(white: 0.12, alpha: 1)
            case 1:
                subtitleText = "You've continued already today. Still intentional?"
                iconName = "exclamationmark.bubble"
                secondaryLabel = "Continue"
                background = UIColor(red: 0.18, green: 0.14, blue: 0.10, alpha: 1)
            default:
                // No API to delay Continue — copy/icon only.
                subtitleText = "Several Continues today. Sure this is worth a window?"
                iconName = "exclamationmark.triangle.fill"
                secondaryLabel = "Continue anyway"
                background = UIColor(red: 0.22, green: 0.10, blue: 0.10, alpha: 1)
            }
        } else {
            subtitleText = "Pause a beat. What did you come here for?"
            iconName = "pause.circle"
            secondaryLabel = "Continue"
            background = UIColor(white: 0.12, alpha: 1)
        }

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: background,
            icon: UIImage(systemName: iconName),
            title: ShieldConfiguration.Label(text: titleText, color: .white),
            subtitle: ShieldConfiguration.Label(text: subtitleText, color: UIColor(white: 0.85, alpha: 1)),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Never Mind", color: .white),
            primaryButtonBackgroundColor: UIColor(red: 0.2, green: 0.45, blue: 0.85, alpha: 1),
            secondaryButtonLabel: ShieldConfiguration.Label(text: secondaryLabel, color: .white)
        )
    }

    private func resolvedAppID(token: ApplicationToken?) -> UUID? {
        guard let token else { return nil }
        if let id = InterventionState.trackedAppID(for: token) { return id }
        if let app = ShieldActionBridge.trackedApp(for: token) { return app.id }
        return nil
    }
}
