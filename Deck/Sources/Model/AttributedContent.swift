import AppKit
import Foundation

/// Helpers for round-tripping note content as RTFD `Data` (Apple-Notes-style:
/// rich text with inline images bundled in).
enum AttributedContent {
    static func data(from string: NSAttributedString) -> Data? {
        let range = NSRange(location: 0, length: string.length)
        return string.rtfd(from: range,
                            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd])
    }

    static func attributedString(from data: Data?) -> NSAttributedString {
        guard let data, !data.isEmpty else { return NSAttributedString(string: "") }
        if let s = try? NSAttributedString(data: data,
                                           options: [.documentType: NSAttributedString.DocumentType.rtfd],
                                           documentAttributes: nil) {
            return s
        }
        // Fallback: try plain RTF, then raw UTF-8.
        if let s = try? NSAttributedString(data: data,
                                           options: [.documentType: NSAttributedString.DocumentType.rtf],
                                           documentAttributes: nil) {
            return s
        }
        return NSAttributedString(string: String(decoding: data, as: UTF8.self))
    }

    /// First non-empty line of plain text, for list snippets.
    static func snippet(from data: Data?, limit: Int = 80) -> String {
        let line = firstLine(from: data)
        return line.count > limit ? String(line.prefix(limit)) + "…" : line
    }

    /// First non-empty line, untruncated — used to auto-title a pasted note.
    static func firstLine(from data: Data?) -> String {
        let plain = attributedString(from: data).string
        for raw in plain.split(whereSeparator: \.isNewline) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if !line.isEmpty { return line }
        }
        return ""
    }
}
