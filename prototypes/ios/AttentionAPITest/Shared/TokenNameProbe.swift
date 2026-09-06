import Foundation
import FamilyControls
import ManagedSettings

/// Probes whether the host process can surface display names for selected tokens.
/// Results are for TEST_RESULTS only — the UI still uses user-typed labels.
enum TokenNameProbe {
    struct Result: Equatable {
        let installedApplicationsCount: Int
        let matchedSelectedTokens: Int
        let namesFoundForSelected: Int
        let sampleName: String?
        let viaApplicationInitNames: Int
        let installedFetchError: String?
        let summary: String
    }

    static func run(selectedTokens: [ApplicationToken]) async -> Result {
        var installed: [Application] = []
        var installedError: String?

        if #available(iOS 26.4, *) {
            do {
                installed = try await FamilyActivityData.shared.installedApplications
            } catch {
                installedError = error.localizedDescription
            }
        } else {
            installedError = "FamilyActivityData requires iOS 26.4+ (device is older)"
        }

        var matched = 0
        var namesFromInstalled = 0
        var sample: String?

        for token in selectedTokens {
            if let app = installed.first(where: { $0.token == token }) {
                matched += 1
                if let name = app.localizedDisplayName, !name.isEmpty {
                    namesFromInstalled += 1
                    if sample == nil { sample = name }
                }
            }
        }

        var viaInit = 0
        for token in selectedTokens {
            let app = Application(token: token)
            if let name = app.localizedDisplayName, !name.isEmpty {
                viaInit += 1
                if sample == nil { sample = name }
            }
        }

        let readable = namesFromInstalled > 0 || viaInit > 0
        var summary: String
        if readable {
            summary = "PARTIAL/YES — names readable for some selected tokens (installedMatches=\(namesFromInstalled) applicationInit=\(viaInit) sample=\(sample ?? "?"))"
        } else if let installedError {
            summary = "NO — FamilyActivityData.installedApplications failed (\(installedError)); Application(token:) also yielded no names"
        } else {
            summary = "NO — could not read display names for selected tokens (installedCount=\(installed.count) matched=\(matched) applicationInit=\(viaInit))"
        }

        return Result(
            installedApplicationsCount: installed.count,
            matchedSelectedTokens: matched,
            namesFoundForSelected: namesFromInstalled,
            sampleName: sample,
            viaApplicationInitNames: viaInit,
            installedFetchError: installedError,
            summary: summary
        )
    }
}
