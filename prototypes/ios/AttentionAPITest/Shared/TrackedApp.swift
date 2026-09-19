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
    /// Access-window length for hard threshold closer (usage duration seconds).
    var windowDurationSeconds: Int

    init(
        id: UUID = UUID(),
        userLabel: String,
        token: ApplicationToken,
        dateAdded: Date = Date(),
        windowDurationSeconds: Int = 300
    ) {
        self.id = id
        self.userLabel = userLabel
        self.token = token
        self.dateAdded = dateAdded
        self.windowDurationSeconds = windowDurationSeconds
    }

    enum CodingKeys: String, CodingKey {
        case id, userLabel, token, dateAdded, windowDurationSeconds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        userLabel = try c.decode(String.self, forKey: .userLabel)
        token = try c.decode(ApplicationToken.self, forKey: .token)
        dateAdded = try c.decode(Date.self, forKey: .dateAdded)
        windowDurationSeconds = try c.decodeIfPresent(Int.self, forKey: .windowDurationSeconds) ?? 300
    }
}
