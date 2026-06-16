import SwiftData
import SwiftUI

/// The card grid — the "open the app and see all my projects" home surface.
/// Cards are glass, tinted by their category theme, floating over the
/// behind-window glass base.
struct ProjectGridView: View {
    let filter: CategoryFilter
    let categories: [Category]
    var onNewProject: () -> Void = {}
    let onOpen: (Project) -> Void

    @Environment(\.modelContext) private var context
    @State private var editingProject: Project?
    @State private var showArchived = false

    private let columns = [GridItem(.adaptive(minimum: 230, maximum: 300),
                                    spacing: DeckMetrics.gridSpacing)]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 34) {
                ForEach(visibleCategories) { category in
                    section(for: category)
                }
            }
            // Extra padding so card glows/shadows have room and aren't clipped
            // by the scroll bounds (no more "hard wall" on the backlight).
            .padding(.horizontal, 28)
            .padding(.vertical, 28)
        }
        .scrollContentBackground(.hidden)
        .scrollEdgeEffectStyle(.soft, for: .all)
        .bottomScrollFade()
        .background(.clear)
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showArchived.toggle()
                } label: {
                    Label(showArchived ? "Hide Archived" : "Show Archived",
                          systemImage: showArchived ? "archivebox.fill" : "archivebox")
                }
                .help(showArchived ? "Hide archived projects" : "Show archived projects")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    onNewProject()
                } label: {
                    Label("New Project", systemImage: "plus")
                }
                .help("New Project (⌘⇧N)")
            }
        }
        .sheet(item: $editingProject) { project in
            EditProjectSheet(project: project, categories: categories)
        }
        .overlay {
            if visibleCategories.allSatisfy({ activeProjects(in: $0).isEmpty }) {
                EmptyStateView(
                    icon: "tray",
                    title: categories.isEmpty ? "No categories yet" : "No projects yet",
                    message: categories.isEmpty
                        ? "Add a category in the sidebar, then create a project."
                        : "Press the + button to add your first project."
                )
            }
        }
    }

    // MARK: Derived

    private var title: String {
        switch filter {
        case .all, .stats: return "All Projects"
        case .category(let c): return c.name
        }
    }

    private var visibleCategories: [Category] {
        switch filter {
        case .all, .stats: return categories
        case .category(let c): return [c]
        }
    }

    private var defaultCategory: Category? {
        if case .category(let c) = filter { return c }
        return categories.first
    }

    private func activeProjects(in category: Category) -> [Project] {
        category.projects
            .filter { showArchived || !$0.isArchived }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: Sections

    @ViewBuilder
    private func section(for category: Category) -> some View {
        let projects = activeProjects(in: category)

        VStack(alignment: .leading, spacing: 14) {
            if case .all = filter {
                sectionHeader(for: category, count: projects.count)
            }

            if projects.isEmpty {
                Text("No projects yet.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 22) {
                    ForEach(projects) { project in
                        Button {
                            onOpen(project)
                        } label: {
                            ProjectCard(project: project, theme: category.theme)
                                .opacity(project.isArchived ? 0.5 : 1)
                        }
                        .buttonStyle(.plain)
                        .contextMenu { projectMenu(project) }
                    }
                }
                // breathing room so the hover glow isn't clipped by the row edge
                .padding(.vertical, 4)
            }
        }
    }

    private func sectionHeader(for category: Category, count: Int) -> some View {
        HStack(spacing: 9) {
            Circle()
                .fill(category.theme.color)
                .frame(width: 10, height: 10)
            Text(category.name)
                .font(.title2.bold())
            Text("\(count)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 1)
                .background(.quaternary, in: Capsule())
        }
    }

    // MARK: Project management

    @ViewBuilder
    private func projectMenu(_ project: Project) -> some View {
        Button("Edit…") { editingProject = project }

        Button(project.isArchived ? "Unarchive" : "Archive") {
            project.isArchived.toggle()
            try? context.save()
        }

        if categories.count > 1 {
            Menu("Move to") {
                ForEach(categories) { category in
                    if category !== project.category {
                        Button(category.name) { move(project, to: category) }
                    }
                }
            }
        }

        Button("Move Up") { reorder(project, by: -1) }
        Button("Move Down") { reorder(project, by: 1) }

        Divider()
        Button("Delete", role: .destructive) {
            context.delete(project)
            try? context.save()
        }
    }

    private func move(_ project: Project, to category: Category) {
        project.category = category
        project.sortOrder = category.projects.count
        try? context.save()
    }

    private func reorder(_ project: Project, by delta: Int) {
        guard let category = project.category else { return }
        var siblings = category.projects.sorted { $0.sortOrder < $1.sortOrder }
        guard let index = siblings.firstIndex(where: { $0 === project }) else { return }
        let target = index + delta
        guard target >= 0, target < siblings.count else { return }
        siblings.swapAt(index, target)
        for (i, p) in siblings.enumerated() { p.sortOrder = i }
        try? context.save()
    }
}
