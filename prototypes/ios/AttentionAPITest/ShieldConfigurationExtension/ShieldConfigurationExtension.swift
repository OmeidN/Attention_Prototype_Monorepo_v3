import ManagedSettings
import ManagedSettingsUI
import UIKit

/// M05 chrome + M11 friction levels from App Group Continue counts.
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
        InterventionState.ensureToday()

        let label = ShieldCopySettings.userLabel(for: token) ?? "NO_LABEL"
        let appID = token.flatMap { InterventionState.trackedAppID(for: $0) }

        let titleText = "Attention — \(label)"

        let subtitleText: String
        let iconName: String
        let secondaryLabel: String

        guard ShieldCopySettings.suite != nil else {
            return ShieldConfiguration(
                backgroundBlurStyle: .systemMaterial,
                backgroundColor: UIColor(white: 0.12, alpha: 1),
                icon: UIImage(systemName: "questionmark.circle"),
                title: ShieldConfiguration.Label(text: titleText, color: .white),
                subtitle: ShieldConfiguration.Label(
                    text: "STATE_UNAVAILABLE — extension could not open App Group. Use one static shield; progression→goals/XP.",
                    color: UIColor(white: 0.85, alpha: 1)
                ),
                primaryButtonLabel: ShieldConfiguration.Label(text: "Never Mind", color: .white),
                primaryButtonBackgroundColor: UIColor(red: 0.2, green: 0.45, blue: 0.85, alpha: 1),
                secondaryButtonLabel: ShieldConfiguration.Label(text: "Continue", color: .white)
            )
        }

        if let appID {
            let continues = InterventionState.continueCount(appID: appID)
            let level = InterventionState.level(forContinueCount: continues)
            InterventionState.markLevelShown(level: level, label: label)

            switch level {
            case 0:
                subtitleText = "L0 soft: pause a beat. continues_today=\(continues) (shared OK)"
                iconName = "hourglass"
                secondaryLabel = "Continue"
            case 1:
                subtitleText = "L1 reminder: is this intentional? continues_today=\(continues) (shared OK)"
                iconName = "exclamationmark.bubble"
                secondaryLabel = "Continue"
            default:
                // ShieldConfiguration has no API to delay/disable Continue — copy-only L2.
                subtitleText = "L2 Are you sure? continues_today=\(continues) — CONTINUE_DELAY_UNAVAILABLE (shared OK)"
                iconName = "exclamationmark.triangle.fill"
                secondaryLabel = "Continue anyway"
            }
        } else {
            subtitleText = "STATE_UNAVAILABLE for token — L0 static. continues unknown."
            iconName = "hourglass"
            secondaryLabel = "Continue"
        }

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor(white: 0.12, alpha: 1),
            icon: UIImage(systemName: iconName),
            title: ShieldConfiguration.Label(text: titleText, color: .white),
            subtitle: ShieldConfiguration.Label(text: subtitleText, color: UIColor(white: 0.85, alpha: 1)),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Never Mind", color: .white),
            primaryButtonBackgroundColor: UIColor(red: 0.2, green: 0.45, blue: 0.85, alpha: 1),
            secondaryButtonLabel: ShieldConfiguration.Label(text: secondaryLabel, color: .white)
        )
    }
}
