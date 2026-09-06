import Foundation
import FamilyControls
import ManagedSettings

/// One distracting app the user chose to track.
///
/// `id` is the primary key everywhere. The token is a live handle that can be
/// refreshed later if iOS silently reissues it — never key history by token.
struct TrackedApp: Identifiable, Codable, Equatable {
    let id: UUID
    var userLabel: String
    var token: ApplicationToken
    let dateAdded: Date
}
