import SwiftData
import SwiftUI

/// The middle column once a project is open: a back affordance, lightweight
/// filters, and the note list. Done items are hidden by default — they only
/// appear when "Show Done" is on. Selection is tinted with the category theme.
struct NoteListPane: View {
    @Bindable var project: Project
    @Binding var selectedNote: Note?
    let onBack: () -> Void

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var drag: DragController
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @State private var showDone = false
    @State private var typeFilter: NoteTypeFilter = .all

    private var theme: CategoryTheme { project.category?.theme ?? .blue }

    var body: some View {
        VStack(spacing: 0) {
            header
            filterBar
            Divider()
            noteList
        }
        .background(.clear)
        .focusedSceneValue(\.newNote, addNote)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onBack) {
                Label("All Projects", systemImage: "chevron.left")
                    .font(.callout)
                    .foregroundStyle(theme.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.capsule)

            HStack(spacing: 9) {
                Text(project.emoji ?? "📁").font(.title)
                Text(project.name)
                    .font(.title2.bold())
                    .lineLimit(1)
                Spacer(minLength: 8)
                // New Note lives here — scoped to the notes column, not the window corner.
                Button(action: addNote) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(theme.color)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .help("New Note (⌘N)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            Picker("Type", selection: $typeFilter) {
                ForEach(NoteTypeFilter.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.menu)
            .fixedSize()

            Spacer()

            if doneCount > 0 {
                Button {
                    showDone.toggle()
                } label: {
                    Label(showDone ? "Hide Done" : "Show Done (\(doneCount))",
                          systemImage: showDone ? "eye.slash" : "checkmark.circle")
                        .font(.callout)
                        .foregroundStyle(showDone ? theme.color : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var noteList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(visibleNotes) { note in
                    NoteRow(note: note, tint: theme.color,
                            isSelected: selectedNote == note)
                        .contentShape(.rect(cornerRadius: 8))
                        .onTapGesture { selectedNote = note }
                        .noteDragGesture(note, drag, context) { result in
                            if let (kind, n) = result, kind == .delete, selectedNote == n {
                                selectedNote = nil
                            }
                        }
                        .contextMenu { NoteContextMenu(note: note, categories: categories) {
                            if selectedNote == note { selectedNote = nil }
                        } }
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .animation(.easeOut(duration: 0.2), value: visibleNotes.count)
        }
        .scrollContentBackground(.hidden)
        .scrollEdgeEffectStyle(.soft, for: .all)
        .bottomScrollFade()
        .overlay {
            if visibleNotes.isEmpty {
                EmptyStateView(icon: "checkmark.circle",
                               title: showDone ? "No notes" : "All clear",
                               message: showDone
                                ? "Add an update with the pencil button."
                                : "No pending updates. Add one, or show done items.")
            }
        }
    }

    // MARK: Derived

    private var doneCount: Int {
        project.notes.filter { $0.status == .done }.count
    }

    private var visibleNotes: [Note] {
        project.notes
            .filter { showDone || $0.status == .pending }
            .filter { typeFilter.matches($0) }
            .sorted { lhs, rhs in
                if lhs.status != rhs.status { return lhs.status == .pending }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    // MARK: Actions

    private func addNote() {
        // Seed the new note's type from the active filter.
        let isBug = typeFilter == .bug || typeFilter == .both
        let isFeature = typeFilter == .feature || typeFilter == .both || typeFilter == .all
        let note = Note(title: "", isBug: isBug, isFeature: isFeature)
        note.project = project
        context.insert(note)
        try? context.save()
        selectedNote = note
    }
}
