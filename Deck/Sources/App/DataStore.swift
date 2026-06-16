import AppKit
import Foundation

/// Owns where Deck's data lives and keeps it safe across app updates.
///
/// - **Data safety:** the SwiftData store lives in `Application Support/Deck/`,
///   OUTSIDE the app bundle, so replacing Deck.app (a GitHub/Sparkle update)
///   never touches user data. A timestamped backup is taken on every launch.
/// - **Self-cleaning:** only the newest `keepBackups` snapshots are kept; older
///   ones are pruned so backups don't accumulate over time.
enum DataStore {
    static let keepBackups = 7

    static var folder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Deck", isDirectory: true)
    }
    static var storeURL: URL { folder.appendingPathComponent("Deck.store") }
    static var backupsFolder: URL { folder.appendingPathComponent("Backups", isDirectory: true) }

    /// The three files SwiftData/SQLite writes (WAL mode).
    private static var storeFileURLs: [URL] {
        ["", "-wal", "-shm"].map { URL(fileURLWithPath: storeURL.path + $0) }
    }

    static func prepare() {
        let fm = FileManager.default
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        try? fm.createDirectory(at: backupsFolder, withIntermediateDirectories: true)
    }

    /// Snapshot the current store into `Backups/backup-<timestamp>/` (no-op on first launch).
    @discardableResult
    static func backupNow() -> URL? {
        let fm = FileManager.default
        guard fm.fileExists(atPath: storeURL.path) else { return nil }
        let dest = backupsFolder.appendingPathComponent("backup-\(timestamp())", isDirectory: true)
        try? fm.createDirectory(at: dest, withIntermediateDirectories: true)
        for src in storeFileURLs where fm.fileExists(atPath: src.path) {
            try? fm.copyItem(at: src, to: dest.appendingPathComponent(src.lastPathComponent))
        }
        return dest
    }

    /// Keep only the newest `keepBackups` snapshots.
    static func pruneBackups() {
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(at: backupsFolder,
                                                      includingPropertiesForKeys: nil) else { return }
        let backups = items
            .filter { $0.lastPathComponent.hasPrefix("backup-") }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }   // timestamp names sort chronologically
        for old in backups.dropFirst(keepBackups) {
            try? fm.removeItem(at: old)
        }
    }

    static var backupCount: Int {
        let fm = FileManager.default
        let items = (try? fm.contentsOfDirectory(at: backupsFolder, includingPropertiesForKeys: nil)) ?? []
        return items.filter { $0.lastPathComponent.hasPrefix("backup-") }.count
    }

    static func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([folder])
    }

    private static func timestamp() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd-HHmmss"
        return f.string(from: Date())
    }
}
