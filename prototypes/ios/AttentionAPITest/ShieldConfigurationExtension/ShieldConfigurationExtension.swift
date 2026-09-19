import ManagedSettings
import ManagedSettingsUI
import UIKit

/// P03 product shield chrome. Static pause copy (L0–L2 friction copy is P05).
/// No lab “variant A/B” or `continues_today=(shared OK)` debug in the shipping subtitle.
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
        let label = ShieldCopySettings.userLabel(for: token) ?? "app"
        let titleText = "Attention — \(label)"

        guard ShieldCopySettings.suite != nil else {
            return ShieldConfiguration(
                backgroundBlurStyle: .systemMaterial,
                backgroundColor: UIColor(white: 0.12, alpha: 1),
                icon: UIImage(systemName: "pause.circle"),
                title: ShieldConfiguration.Label(text: titleText, color: .white),
                subtitle: ShieldConfiguration.Label(
                    text: "Pause. Shared state unavailable — use Never Mind or Continue.",
                    color: UIColor(white: 0.85, alpha: 1)
                ),
                primaryButtonLabel: ShieldConfiguration.Label(text: "Never Mind", color: .white),
                primaryButtonBackgroundColor: UIColor(red: 0.2, green: 0.45, blue: 0.85, alpha: 1),
                secondaryButtonLabel: ShieldConfiguration.Label(text: "Continue", color: .white)
            )
        }

        // Product static copy for P03. P05 will escalate tone from continues_today.
        let subtitleText = "Pause a beat. What did you come here for?"

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor(white: 0.12, alpha: 1),
            icon: UIImage(systemName: "pause.circle"),
            title: ShieldConfiguration.Label(text: titleText, color: .white),
            subtitle: ShieldConfiguration.Label(text: subtitleText, color: UIColor(white: 0.85, alpha: 1)),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Never Mind", color: .white),
            primaryButtonBackgroundColor: UIColor(red: 0.2, green: 0.45, blue: 0.85, alpha: 1),
            secondaryButtonLabel: ShieldConfiguration.Label(text: "Continue", color: .white)
        )
    }
}
