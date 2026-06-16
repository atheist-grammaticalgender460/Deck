import SwiftUI

/// A compact emoji field with an Apple-Intelligence "Suggest" button
/// (shown only when on-device generation is available).
struct EmojiField: View {
    let projectName: String
    @Binding var emoji: String
    @State private var loading = false

    var body: some View {
        HStack(spacing: 10) {
            TextField("🙂", text: $emoji)
                .textFieldStyle(.roundedBorder)
                .controlSize(.large)
                .multilineTextAlignment(.center)
                .frame(width: 64)

            if EmojiSuggester.isAvailable {
                Button {
                    Task {
                        loading = true
                        if let e = await EmojiSuggester.suggest(for: projectName) { emoji = e }
                        loading = false
                    }
                } label: {
                    if loading {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Suggest", systemImage: "sparkles")
                    }
                }
                .disabled(projectName.trimmingCharacters(in: .whitespaces).isEmpty || loading)
                .help("Suggest an emoji with Apple Intelligence")
            }
        }
    }
}
