import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
            UpdatesSettingsView()
                .tabItem { Label("Updates", systemImage: "arrow.down.circle") }
        }
        .frame(width: 480, height: 300)
    }
}

private var appVersion: String {
    let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    return "\(v) (\(b))"
}

struct GeneralSettingsView: View {
    @State private var backupCount = DataStore.backupCount

    var body: some View {
        Form {
            LabeledContent("App", value: "Deck")
            LabeledContent("Version", value: appVersion)

            Section("Data") {
                LabeledContent("Backups", value: "\(backupCount) kept")
                Button("Back Up Now") {
                    DataStore.backupNow()
                    DataStore.pruneBackups()
                    backupCount = DataStore.backupCount
                }
                Button("Reveal Data in Finder…") { DataStore.revealInFinder() }
                Text("Your notes live in Application Support/Deck — outside the app, so updates never touch them. A backup is taken each launch (newest \(DataStore.keepBackups) kept).")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

struct UpdatesSettingsView: View {
    @ObservedObject private var updater = UpdaterModel.shared

    var body: some View {
        Form {
            LabeledContent("Current version", value: appVersion)

            if updater.updateAvailable {
                LabeledContent("Latest version", value: updater.latestVersion ?? "—")
                Section {
                    Button("Install Update…") { updater.checkForUpdates() }
                        .buttonStyle(.borderedProminent)
                    Text("A new version is available. Installing keeps your data — your notes live outside the app — and replaces the old build.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    Button("Check for Updates…") { updater.checkForUpdates() }
                        .disabled(!updater.canCheck)
                    Text("Updates are manual — nothing downloads on its own. When a new version is on GitHub, an Update badge appears in the sidebar; click it (or this button) for a one-click download → install.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }
}
