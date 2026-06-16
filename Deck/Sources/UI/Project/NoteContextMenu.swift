import SwiftData
import SwiftUI

/// Right-click actions for a note, shared by the note list and search results:
/// mark done/pending, move to another category→project, delete.
struct NoteContextMenu: View {
    let note: Note
    let categories: [Category]
    var onRemoved: () -> Void = {}

    @Environment(\.modelContext) private var context

    var body: some View {
        Button(note.status == .pending ? "Mark Done" : "Mark Pending") {
            note.setStatus(note.status == .pending ? .done : .pending)
            try? context.save()
        }

        Menu("Move to") {
            ForEach(categories) { category in
                Menu(category.name) {
                    let projects = category.projects
                        .filter { !$0.isArchived }
                        .sorted { $0.sortOrder < $1.sortOrder }
                    if projects.isEmpty {
                        Text("No projects")
                    } else {
                        ForEach(projects) { project in
                            Button {
                                note.project = project
                                note.updatedAt = Date()
                                try? context.save()
                                onRemoved()
                            } label: {
                                if note.project === project {
                                    Label(project.name, systemImage: "checkmark")
                                } else {
                                    Text(project.name)
                                }
                            }
                        }
                    }
                }
            }
        }

        Divider()

        Button("Delete", role: .destructive) {
            context.delete(note)
            try? context.save()
            onRemoved()
        }
    }
}
