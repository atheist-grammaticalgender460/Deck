import SwiftData
import SwiftUI

struct EditCategorySheet: View {
    @Bindable var category: Category

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Edit Category")
                .font(.title2.bold())

            TextField("Name", text: $category.name)
                .textFieldStyle(.roundedBorder)
                .controlSize(.large)

            Text("Theme").font(.callout.weight(.medium)).foregroundStyle(.secondary)
            ThemePicker(theme: $category.theme)

            HStack {
                Spacer()
                Button("Done") {
                    try? context.save()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 380)
    }
}
