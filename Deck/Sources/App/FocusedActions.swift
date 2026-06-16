import SwiftUI

/// Focused-scene actions so menu-bar commands resolve to whatever the active
/// view publishes (e.g. ⌘N = New Note only when a project is open).
struct NewNoteAction: FocusedValueKey { typealias Value = () -> Void }
struct NewProjectAction: FocusedValueKey { typealias Value = () -> Void }
struct NewCategoryAction: FocusedValueKey { typealias Value = () -> Void }

extension FocusedValues {
    var newNote: (() -> Void)? {
        get { self[NewNoteAction.self] }
        set { self[NewNoteAction.self] = newValue }
    }
    var newProject: (() -> Void)? {
        get { self[NewProjectAction.self] }
        set { self[NewProjectAction.self] = newValue }
    }
    var newCategory: (() -> Void)? {
        get { self[NewCategoryAction.self] }
        set { self[NewCategoryAction.self] = newValue }
    }
}

/// File-menu "New" commands. Each greys out when the active view doesn't offer it.
struct NewItemCommands: View {
    @FocusedValue(\.newNote) private var newNote
    @FocusedValue(\.newProject) private var newProject
    @FocusedValue(\.newCategory) private var newCategory

    var body: some View {
        Button("New Note") { newNote?() }
            .keyboardShortcut("n", modifiers: .command)
            .disabled(newNote == nil)
        Button("New Project…") { newProject?() }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            .disabled(newProject == nil)
        Button("New Category…") { newCategory?() }
            .keyboardShortcut("n", modifiers: [.command, .option])
            .disabled(newCategory == nil)
    }
}
