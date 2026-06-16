import SwiftData
import SwiftUI

struct EditProjectSheet: View {
    @Bindable var project: Project
    let categories: [Category]

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var categoryID: PersistentIdentifier?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Edit Project")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 14) {
                field("Name") {
                    TextField("Project name", text: $project.name)
                        .textFieldStyle(.roundedBorder)
                        .controlSize(.large)
                }
                field("Emoji") {
                    EmojiField(projectName: project.name, emoji: emojiBinding)
                }
                field("Category") {
                    Picker("", selection: $categoryID) {
                        ForEach(categories) { Text($0.name).tag(Optional($0.persistentModelID)) }
                    }
                    .labelsHidden()
                    .fixedSize()
                }
                field("") {
                    Toggle("Archived", isOn: $project.isArchived)
                        .toggleStyle(.switch)
                }
            }

            HStack {
                Button(role: .destructive) {
                    context.delete(project)
                    try? context.save()
                    dismiss()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                Spacer()
                Button("Done") { save() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 4)
        }
        .padding(22)
        .frame(width: 420)
        .onAppear { categoryID = project.category?.persistentModelID }
    }

    private func field<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)
            content()
            Spacer(minLength: 0)
        }
    }

    private var emojiBinding: Binding<String> {
        Binding(get: { project.emoji ?? "" },
                set: { project.emoji = $0.isEmpty ? nil : $0 })
    }

    private func save() {
        if let id = categoryID,
           let category = categories.first(where: { $0.persistentModelID == id }) {
            project.category = category
        }
        try? context.save()
        dismiss()
    }
}
