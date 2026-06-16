import SwiftData
import SwiftUI

struct NewProjectSheet: View {
    let categories: [Category]
    var preselected: Category?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = ""
    @State private var categoryID: PersistentIdentifier?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("New Project")
                .font(.title2.bold())

            if categories.isEmpty {
                Text("Create a category in the sidebar first.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    field("Name") {
                        TextField("Project name", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .controlSize(.large)
                    }
                    field("Emoji") {
                        EmojiField(projectName: name, emoji: $emoji)
                    }
                    field("Category") {
                        Picker("", selection: $categoryID) {
                            ForEach(categories) { Text($0.name).tag(Optional($0.persistentModelID)) }
                        }
                        .labelsHidden()
                        .fixedSize()
                    }
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Create") { create() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canCreate)
            }
            .padding(.top, 4)
        }
        .padding(22)
        .frame(width: 420)
        .onAppear {
            categoryID = preselected?.persistentModelID ?? categories.first?.persistentModelID
        }
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

    private var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && categoryID != nil
    }

    private func create() {
        guard let categoryID,
              let category = categories.first(where: { $0.persistentModelID == categoryID })
        else { return }

        let project = Project(
            name: name.trimmingCharacters(in: .whitespaces),
            emoji: emoji.isEmpty ? nil : emoji,
            sortOrder: category.projects.count
        )
        project.category = category
        context.insert(project)
        try? context.save()
        dismiss()
    }
}
