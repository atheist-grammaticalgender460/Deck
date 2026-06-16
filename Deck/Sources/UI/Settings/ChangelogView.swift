import SwiftUI

/// Renders the bundled CHANGELOG.md as a readable "What's New" list, newest first.
struct ChangelogView: View {
    private let entries = ChangelogView.load()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if entries.isEmpty {
                    Text("No changelog found.").foregroundStyle(.secondary)
                }
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Version \(entry.version)")
                            .font(.headline)
                        ForEach(Array(entry.items.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 5))
                                    .foregroundStyle(.tertiary)
                                Text(item)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
    }

    // MARK: Parsing

    struct Entry: Identifiable {
        let id = UUID()
        let version: String
        let items: [String]
    }

    static func load() -> [Entry] {
        guard let url = Bundle.main.url(forResource: "CHANGELOG", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        var entries: [Entry] = []
        var version: String?
        var items: [String] = []
        func flush() {
            if let v = version, !items.isEmpty { entries.append(Entry(version: v, items: items)) }
            items = []
        }
        for raw in text.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("## ") {
                flush()
                version = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                items.append(String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces))
            }
        }
        flush()
        return entries
    }
}
