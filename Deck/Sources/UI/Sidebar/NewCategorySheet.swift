import SwiftData
import SwiftUI

struct NewCategorySheet: View {
    let sortOrder: Int

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var theme: CategoryTheme = .blue

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("New Category")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 14) {
                TextField("Name (e.g. Work, Wife, Kamal)", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.large)

                Text("Theme")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.secondary)
                ThemePicker(theme: $theme)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Create") { create() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(22)
        .frame(width: 380)
    }

    private func create() {
        let category = Category(
            name: name.trimmingCharacters(in: .whitespaces),
            theme: theme,
            sortOrder: sortOrder
        )
        context.insert(category)
        try? context.save()
        dismiss()
    }
}
