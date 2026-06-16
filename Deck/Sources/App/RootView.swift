import SwiftData
import SwiftUI

/// Which categories the project grid is showing.
enum CategoryFilter: Hashable {
    case all
    case stats
    case category(Category)
}

/// Sidebar + one big area. The area is full-screen for the dashboard and stats;
/// opening a project expands it into a notes·editor split (sidebar + 2 = 3 panes).
struct RootView: View {
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var filter: CategoryFilter = .all
    @State private var selectedProject: Project?
    @State private var selectedNote: Note?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var searchText = ""
    @State private var showingNewProject = false
    @StateObject private var drag = DragController()

    var body: some View {
        ZStack {
            splitView
                .blur(radius: drag.isActive ? 14 : 0)
            if drag.isActive {
                DragOverlay()
            }
        }
        .environmentObject(drag)
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: drag.isActive)
        .sheet(isPresented: $showingNewProject) {
            NewProjectSheet(categories: categories, preselected: preselectedCategory)
        }
        .focusedSceneValue(\.newProject, categories.isEmpty ? nil : { showingNewProject = true })
    }

    /// Best category to preselect when creating a project from the menu.
    private var preselectedCategory: Category? {
        if let p = selectedProject { return p.category }
        if case .category(let c) = filter { return c }
        return categories.first
    }

    private var splitView: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            CategorySidebar(
                current: filter,
                showsSelection: searchText.trimmingCharacters(in: .whitespaces).isEmpty,
                onSelect: { f in
                    filter = f
                    selectedProject = nil
                    selectedNote = nil
                    searchText = ""
                }
            )
            .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 300)
        } detail: {
            mainArea
        }
        .navigationTitle("")
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search all notes")
    }

    @ViewBuilder
    private var mainArea: some View {
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            SearchResultsView(query: searchText) { note in
                selectedProject = note.project
                selectedNote = note
            }
        } else if case .stats = filter {
            StatsView()
        } else if let project = selectedProject {
            ProjectWorkspace(
                project: project,
                selectedNote: $selectedNote,
                onBack: {
                    selectedProject = nil
                    selectedNote = nil
                }
            )
        } else {
            ProjectGridView(
                filter: filter,
                categories: categories,
                onNewProject: { showingNewProject = true },
                onOpen: { project in
                    selectedProject = project
                    selectedNote = nil
                }
            )
        }
    }
}

/// The 3rd pane that appears once a project is opened: notes list · editor.
struct ProjectWorkspace: View {
    @Bindable var project: Project
    @Binding var selectedNote: Note?
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            NoteListPane(project: project, selectedNote: $selectedNote, onBack: onBack)
                .frame(minWidth: 280, idealWidth: 340, maxWidth: 380)

            Divider()

            Group {
                if let note = selectedNote {
                    NoteEditorView(note: note, theme: project.category?.theme ?? .blue)
                        .id(note.persistentModelID)
                } else {
                    EmptyStateView(icon: "note.text", title: "Pick a note",
                                   message: "Select a note, or add a new one.")
                }
            }
            // maxWidth .infinity makes the editor fill remaining space rather than
            // demand its intrinsic width (which was overflowing the window).
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Centered empty-state placeholder — native `ContentUnavailableView` so it
/// matches macOS styling (icon size, hierarchy, spacing) for free.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(message)
        }
    }
}
