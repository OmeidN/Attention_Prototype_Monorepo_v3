import SwiftUI
import FamilyControls
import ManagedSettings

/// Carries one new token into the naming sheet. Using `sheet(item:)` avoids
/// presenting with an empty token list (a common `isPresented` race).
struct NamingSession: Identifiable {
    let id = UUID()
    let token: ApplicationToken
}

/// Editable draft for the single new opaque token.
struct NamingDraft {
    let token: ApplicationToken
    var label: String
}

/// Name exactly one newly added app. Blank label cannot continue.
struct NamingAppsView: View {
    let token: ApplicationToken
    let onCancel: () -> Void
    let onSave: (String, ApplicationToken) -> Void

    @State private var draft: NamingDraft
    @State private var inlineError: String?

    init(
        token: ApplicationToken,
        onCancel: @escaping () -> Void,
        onSave: @escaping (String, ApplicationToken) -> Void
    ) {
        self.token = token
        self.onCancel = onCancel
        self.onSave = onSave
        _draft = State(initialValue: NamingDraft(token: token, label: ""))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("One app at a time. Apple does not give us the real name or logo — type a label for the app you just picked (e.g. TikTok).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Name this app") {
                    HStack(spacing: 12) {
                        Image(systemName: "app.dashed")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .frame(width: 36, height: 36)
                        TextField("e.g. TikTok", text: $draft.label)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                    }
                }

                if let inlineError {
                    Section {
                        Text(inlineError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Name app")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") {
                        attemptContinue()
                    }
                }
            }
        }
    }

    private func attemptContinue() {
        let trimmed = draft.label.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            inlineError = "Type a name before continuing. The field is blank."
            TestLogger.shared.log("ATTN-M03", "naming_blocked blank_row=1")
            TestLogger.shared.log("ATTN-P01", "naming_blocked blank_row=1")
            return
        }
        inlineError = nil
        onSave(trimmed, draft.token)
    }
}
