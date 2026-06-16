import SwiftData
import SwiftUI

/// Results for the global search field — matches note titles and body text across
/// every project, grouped by project.
struct SearchResultsView: View {
    let query: String
    let onOpen: (Note) -> Void

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var drag: DragController
    @Query private var notes: [Note]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    private var results: [Note] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        return notes
            .filter { note in
                if note.title.lowercased().contains(q) { return true }
                return AttributedContent.attributedString(from: note.contentRTFD)
                    .string.lowercased().contains(q)
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        Group {
            if results.isEmpty {
                EmptyStateView(icon: "magnifyingglass", title: "No matches",
                               message: "Nothing matches “\(query)”.")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.top, 6)

                        ForEach(results) { note in
                            resultRow(note)
                                .contentShape(.rect(cornerRadius: 8))
                                .onTapGesture { onOpen(note) }
                                .noteDragGesture(note, drag, context)
                                .contextMenu { NoteContextMenu(note: note, categories: categories) }
                        }
                    }
                    .padding(10)
                }
                .scrollContentBackground(.hidden)
                .scrollEdgeEffectStyle(.soft, for: .all)
                .bottomScrollFade()
            }
        }
        .navigationTitle("Search")
    }

    private func resultRow(_ note: Note) -> some View {
        let theme = note.project?.category?.theme ?? .blue
        return HStack(alignment: .top, spacing: 11) {
            TypeIcons(note: note)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let project = note.project {
                        Label(project.name, systemImage: project.emoji == nil ? "folder" : "")
                            .labelStyle(.titleOnly)
                            .foregroundStyle(theme.color)
                    }
                    let snippet = AttributedContent.snippet(from: note.contentRTFD)
                    if !snippet.isEmpty {
                        Text("· \(snippet)").foregroundStyle(.tertiary).lineLimit(1)
                    }
                }
                .font(.subheadline)
            }
            Spacer(minLength: 4)
            if note.status == .done {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).padding(.top, 2)
            }
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 10)
    }
}
