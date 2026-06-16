import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Drives formatting/export actions on the editor's NSTextView. One instance per
/// open note (the editor view owns it as a @StateObject keyed by note id).
@MainActor
final class RichTextController: ObservableObject {
    weak var textView: NSTextView?

    // MARK: Inline traits

    func toggleBold() { toggleTrait(.boldFontMask) }
    func toggleItalic() { toggleTrait(.italicFontMask) }

    private func toggleTrait(_ trait: NSFontTraitMask) {
        guard let tv = textView, let storage = tv.textStorage else { return }
        let fm = NSFontManager.shared
        let range = tv.selectedRange()

        func toggled(_ font: NSFont, on: Bool) -> NSFont {
            on ? fm.convert(font, toNotHaveTrait: trait) : fm.convert(font, toHaveTrait: trait)
        }

        if range.length == 0 {
            let current = (tv.typingAttributes[.font] as? NSFont) ?? .systemFont(ofSize: NSFont.systemFontSize + 1)
            let isOn = fm.traits(of: current).contains(trait)
            tv.typingAttributes[.font] = toggled(current, on: isOn)
            return
        }

        let firstFont = (storage.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont)
            ?? .systemFont(ofSize: NSFont.systemFontSize + 1)
        let isOn = fm.traits(of: firstFont).contains(trait)

        guard tv.shouldChangeText(in: range, replacementString: nil) else { return }
        storage.beginEditing()
        storage.enumerateAttribute(.font, in: range) { value, subrange, _ in
            let font = (value as? NSFont) ?? .systemFont(ofSize: NSFont.systemFontSize + 1)
            storage.addAttribute(.font, value: toggled(font, on: isOn), range: subrange)
        }
        storage.endEditing()
        tv.didChangeText()
    }

    // MARK: Bulleted list

    /// Toggles a tiered bullet on the current paragraph (Tab nests, Shift+Tab
    /// outdents). The list behavior lives in `DeckTextView`.
    func toggleBullets() {
        (textView as? DeckTextView)?.toggleBulletList()
    }

    // MARK: Image insertion

    func insertImage() {
        guard let tv = textView else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .gif, .tiff, .heic]
        panel.allowsMultipleSelection = false
        panel.begin { response in
            guard response == .OK, let url = panel.url, let data = try? Data(contentsOf: url) else { return }
            let wrapper = FileWrapper(regularFileWithContents: data)
            wrapper.preferredFilename = url.lastPathComponent
            let attachment = NSTextAttachment(fileWrapper: wrapper)
            let attrString = NSAttributedString(attachment: attachment)
            let range = tv.selectedRange()
            guard tv.shouldChangeText(in: range, replacementString: nil) else { return }
            tv.textStorage?.replaceCharacters(in: range, with: attrString)
            tv.didChangeText()
        }
    }

    // MARK: Copy / export

    private var fullRange: NSRange {
        NSRange(location: 0, length: textView?.textStorage?.length ?? 0)
    }

    /// Copies the whole note as rich text (RTFD + RTF + plain) so paste into
    /// Mail / Notes keeps formatting and inline images.
    func copyAll() {
        guard let storage = textView?.textStorage else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        let range = fullRange
        if let rtfd = storage.rtfd(from: range, documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]) {
            pb.setData(rtfd, forType: .rtfd)
        }
        if let rtf = storage.rtf(from: range, documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]) {
            pb.setData(rtf, forType: .rtf)
        }
        pb.setString(storage.string, forType: .string)
    }

    func exportPDF(suggestedName: String) {
        guard let tv = textView else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = sanitized(suggestedName) + ".pdf"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let data = tv.dataWithPDF(inside: tv.bounds)
            try? data.write(to: url)
        }
    }

    func exportRTFD(suggestedName: String) {
        guard let storage = textView?.textStorage else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType("com.apple.rtfd") ?? .rtf]
        panel.nameFieldStringValue = sanitized(suggestedName) + ".rtfd"
        let range = fullRange
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            if let wrapper = try? storage.fileWrapper(
                from: range,
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]
            ) {
                try? wrapper.write(to: url, options: .atomic, originalContentsURL: nil)
            }
        }
    }

    private func sanitized(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = trimmed.isEmpty ? "Note" : trimmed
        return cleaned.replacingOccurrences(of: "/", with: "-")
    }
}
