import Foundation

/// Shared key/value state for the experiments.
///
/// Backed by standard `UserDefaults`. M00/M01 deliberately have no App Group
/// capability; when the extensions arrive and need to see the same state, the
/// suite swaps to an App Group and this read/write surface stays the same.
final class ExperimentStore {
    static let shared = ExperimentStore()

    private let defaults: UserDefaults

    /// Shown on the Setup tab so the prototype never claims shared storage it
    /// does not actually have.
    let backingDescription = "UserDefaults.standard (App Group arrives with the extensions)"

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
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
}
