import AppKit
import SwiftData
import SwiftUI

@main
struct DeckApp: App {
    let container: ModelContainer
    @StateObject private var updater = UpdaterModel.shared

    init() {
        do {
            // Data safety: store lives in Application Support/Deck (outside the app
            // bundle), so updates never touch it. Snapshot before opening, then
            // self-clean old snapshots.
            DataStore.prepare()
            DataStore.backupNow()
            DataStore.pruneBackups()

            let config = ModelConfiguration(url: DataStore.storeURL)
            container = try ModelContainer(
                for: Category.self, Project.self, Note.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .background(GlassWindowBackground().ignoresSafeArea())
                .frame(minWidth: 960, minHeight: 620)
                .task { UpdaterModel.shared.checkSilently() }
        }
        .modelContainer(container)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1100, height: 720)
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .newItem) {
                NewItemCommands()
            }
            CommandGroup(after: .appInfo) {
                CheckForUpdatesCommand()
            }
            CommandGroup(after: .pasteboard) {
                Button("Paste and Match Style") {
                    NSApp.sendAction(#selector(NSTextView.pasteAsPlainText(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("v", modifiers: [.control, .shift])
            }
        }

        Settings {
            SettingsView()
        }
        .modelContainer(container)
    }
}
