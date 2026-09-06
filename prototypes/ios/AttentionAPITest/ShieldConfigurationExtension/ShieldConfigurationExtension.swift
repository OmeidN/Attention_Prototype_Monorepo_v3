import ManagedSettings
import ManagedSettingsUI
import UIKit

/// M05: custom shield chrome only. Button *actions* are M06.
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
        let variant = ShieldCopySettings.readVariant()
        let label = ShieldCopySettings.userLabel(for: token)

        let titleText: String
        if let label {
            titleText = "Attention — \(label)"
        } else {
            titleText = "Attention — NO_LABEL"
        }

        let subtitleText: String
        if let variant {
            switch variant {
            case "A":
                subtitleText = "Variant A: pause before opening. (shared OK)"
            case "B":
                subtitleText = "Variant B: intentional choice check. (shared OK)"
            default:
                subtitleText = "Variant \(variant) (shared OK)"
            }
        } else {
            subtitleText = "NO_SHARED_STATE — extension could not read App Group variant"
        }

        let icon = UIImage(systemName: "hourglass")

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor(white: 0.12, alpha: 1),
            icon: icon,
            title: ShieldConfiguration.Label(text: titleText, color: .white),
            subtitle: ShieldConfiguration.Label(text: subtitleText, color: UIColor(white: 0.85, alpha: 1)),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Never Mind", color: .white),
            primaryButtonBackgroundColor: UIColor(red: 0.2, green: 0.45, blue: 0.85, alpha: 1),
            secondaryButtonLabel: ShieldConfiguration.Label(text: "Continue", color: .white)
        )
    }
}
