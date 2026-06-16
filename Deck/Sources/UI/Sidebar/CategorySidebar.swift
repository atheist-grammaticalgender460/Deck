import SwiftData
import SwiftUI

struct CategorySidebar: View {
    let current: CategoryFilter
    /// True when the sidebar selection should be highlighted (no project open / not searching).
    let showsSelection: Bool
    let onSelect: (CategoryFilter) -> Void

    @Environment(\.modelContext) private var context
    @ObservedObject private var updater = UpdaterModel.shared
    @Environment(\.openSettings) private var openSettings
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var showingNewCategory = false
    @State private var editingCategory: Category?

    var body: some View {
        List {
            Button { onSelect(.all) } label: {
                SidebarRow(title: "All Projects", systemImage: "square.grid.2x2",
                           iconColor: .secondary, accent: .accentColor, active: isActive(.all))
            }
            .buttonStyle(.plain)
            .listRowInsets(rowInsets)
            .listRowSeparator(.hidden)

            Button { onSelect(.stats) } label: {
                SidebarRow(title: "Stats", systemImage: "chart.bar.xaxis",
                           iconColor: .secondary, accent: .accentColor, active: isActive(.stats))
            }
            .buttonStyle(.plain)
            .listRowInsets(rowInsets)
            .listRowSeparator(.hidden)

            Section("Categories") {
                // Tap-gesture rows (not Buttons) so List's drag-to-reorder isn't
                // intercepted — drag a category to reorder, Apple-Notes style.
                ForEach(categories) { category in
                    SidebarRow(title: category.name, systemImage: "folder.fill",
                               iconColor: category.theme.color, accent: category.theme.color,
                               count: category.openItemCount, active: isActive(.category(category)))
                        .contentShape(Rectangle())
                        .onTapGesture { onSelect(.category(category)) }
                        .listRowInsets(rowInsets)
                        .listRowSeparator(.hidden)
                        .contextMenu { contextMenu(for: category) }
                }
                .onMove(perform: moveCategories)
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                if updater.updateAvailable {
                    Button {
                        openSettings()
                    } label: {
                        Label(updater.latestVersion.map { "Update to \($0)" } ?? "Update available",
                              systemImage: "arrow.down.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .tint(.green)
                    .help("An update is available — open Settings to install")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Button {
                    showingNewCategory = true
                } label: {
                    Label("New Category", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
            }
            .padding(10)
            .animation(.snappy, value: updater.updateAvailable)
        }
        .sheet(isPresented: $showingNewCategory) {
            NewCategorySheet(sortOrder: categories.count)
        }
        .sheet(item: $editingCategory) { category in
            EditCategorySheet(category: category)
        }
        .focusedSceneValue(\.newCategory) { showingNewCategory = true }
    }

    private var rowInsets: EdgeInsets { EdgeInsets(top: 1, leading: 8, bottom: 1, trailing: 8) }

    private func isActive(_ f: CategoryFilter) -> Bool { showsSelection && current == f }

    @ViewBuilder
    private func contextMenu(for category: Category) -> some View {
        Button("Edit…") { editingCategory = category }
        Menu("Theme") {
            // Real colored dots (drawn NSImages) — SF Symbols render monochrome in menus.
            ForEach(CategoryTheme.allCases) { theme in
                Button {
                    category.theme = theme
                    try? context.save()
                } label: {
                    Label {
                        Text(category.theme == theme ? "\(theme.label) ✓" : theme.label)
                    } icon: {
                        Image(nsImage: theme.swatch)
                    }
                }
            }
        }
        Divider()
        Button(role: .destructive) {
            if current == .category(category) { onSelect(.all) }
            context.delete(category)
            try? context.save()
        } label: {
            Label("Delete Category", systemImage: "trash")
        }
    }

    private func moveCategories(from source: IndexSet, to destination: Int) {
        var arr = categories
        arr.move(fromOffsets: source, toOffset: destination)
        for (i, c) in arr.enumerated() { c.sortOrder = i }
        try? context.save()
    }

    private func reorder(_ category: Category, by delta: Int) {
        var arr = categories
        guard let index = arr.firstIndex(where: { $0 === category }) else { return }
        let target = index + delta
        guard target >= 0, target < arr.count else { return }
        arr.swapAt(index, target)
        for (i, c) in arr.enumerated() { c.sortOrder = i }
        try? context.save()
    }
}

private struct SidebarRow: View {
    let title: String
    let systemImage: String
    let iconColor: Color
    let accent: Color
    var count: Int? = nil
    let active: Bool

    @Environment(\.appearsActive) private var appearsActive
    @State private var hovering = false

    /// Selected-and-window-key → full accent + white text. Selected-but-inactive
    /// → muted gray fill with normal text (matches native lists).
    private var emphasized: Bool { active && appearsActive }

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .foregroundStyle(emphasized ? AnyShapeStyle(.white) : AnyShapeStyle(iconColor))
                .frame(width: 20)
            Text(title)
                .foregroundStyle(emphasized ? .white : .primary)
                .lineLimit(1)
            Spacer(minLength: 4)
            if let count {
                Text("\(count)")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(emphasized ? .white.opacity(0.85) : .secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(fill)
        )
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }

    private var fill: AnyShapeStyle {
        if active {
            return emphasized ? AnyShapeStyle(accent) : AnyShapeStyle(Color.secondary.opacity(0.22))
        }
        return hovering ? AnyShapeStyle(Color.primary.opacity(0.06)) : AnyShapeStyle(Color.clear)
    }
}
