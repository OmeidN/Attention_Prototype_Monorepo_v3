import Foundation

/// Shared key/value state for the experiments.
///
/// M03+: App Group suite so future extensions (M04+) can read the same state.
final class ExperimentStore {
    static let shared = ExperimentStore()
    static let appGroupID = "group.com.attention.apitest"

    private let defaults: UserDefaults

    /// Shown on the Setup tab so the prototype never claims shared storage it
    /// does not actually have.
    let backingDescription: String

    private init() {
        if let suite = UserDefaults(suiteName: Self.appGroupID) {
            self.defaults = suite
            self.backingDescription = "App Group \(Self.appGroupID)"
        } else {
            self.defaults = .standard
            self.backingDescription = "FALLBACK UserDefaults.standard (App Group suite unavailable)"
        }
    }

    func bool(_ key: String) -> Bool {
        defaults.bool(forKey: key)
    }

    func setBool(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func string(_ key: String) -> String? {
        defaults.string(forKey: key)
    }

    func setString(_ value: String, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func data(forKey key: String) -> Data? {
        defaults.data(forKey: key)
    }

    func setData(_ value: Data?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func removeObject(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
