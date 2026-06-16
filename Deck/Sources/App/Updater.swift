import Sparkle
import SwiftUI

/// In-app manual updates via Sparkle. Nothing installs in the background
/// (`SUEnableAutomaticChecks` is false). On launch a silent, UI-less probe of the
/// signed appcast tells us whether a newer build exists → we surface a badge. The
/// user decides when to install: triggering the real check offers a one-click
/// download → install → relaunch, with the changelog shown.
final class UpdaterModel: NSObject, ObservableObject, SPUUpdaterDelegate {
    static let shared = UpdaterModel()

    private(set) var controller: SPUStandardUpdaterController!

    @Published var updateAvailable = false
    @Published var latestVersion: String?

    override init() {
        super.init()
        controller = SPUStandardUpdaterController(startingUpdater: true,
                                                  updaterDelegate: self,
                                                  userDriverDelegate: nil)
    }

    var canCheck: Bool { controller.updater.canCheckForUpdates }

    /// User-initiated check — shows Sparkle's install prompt (with release notes).
    func checkForUpdates() { controller.checkForUpdates(nil) }

    /// Silent probe — no UI; flips `updateAvailable` via the delegate callbacks.
    func checkSilently() {
        guard canCheck else { return }
        controller.updater.checkForUpdateInformation()
    }

    // MARK: SPUUpdaterDelegate
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        updateAvailable = true
        latestVersion = item.displayVersionString
    }
    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        updateAvailable = false
        latestVersion = nil
    }
}

/// `Deck ▸ Check for Updates…` menu command.
struct CheckForUpdatesCommand: View {
    @ObservedObject private var updater = UpdaterModel.shared
    var body: some View {
        Button("Check for Updates…") { updater.checkForUpdates() }
            .disabled(!updater.canCheck)
    }
}
