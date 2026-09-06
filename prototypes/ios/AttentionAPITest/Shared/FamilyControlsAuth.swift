import FamilyControls
import Foundation

/// Thin wrapper around `AuthorizationCenter` so Setup can show status without
/// pulling Screen Time calls into unrelated views. M02 only — no picker, no shields.
enum FamilyControlsAuth {
    static var status: AuthorizationStatus {
        AuthorizationCenter.shared.authorizationStatus
    }

    static var statusLabel: String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .denied: return "denied"
        case .approved: return "approved"
        @unknown default: return "unknown(\(String(describing: status)))"
        }
    }

    static func requestIndividual() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    }
}
