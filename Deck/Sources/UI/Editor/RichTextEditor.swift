import AppKit
import SwiftUI

/// Apple-Notes-style rich text editing backed by NSTextView.
/// Content round-trips as RTFD `Data` (rich text + inline images).
///
/// The parent gives each note instance its own editor via `.id(note)`, so this
/// view is rebuilt when the selected note changes — `makeNSView` loads the
/// content and `updateNSView` is a no-op for selection changes.
struct RichTextEditor: NSViewRepresentable {
    @Binding var data: Data?
    var controller: RichTextController?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = DeckTextView()
        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.importsGraphics = true
        textView.allowsImageEditing = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.textContainerInset = NSSize(width: 16, height: 18)
        textView.font = .systemFont(ofSize: NSFont.systemFontSize + 1)
        textView.textColor = .labelColor
        textView.insertionPointColor = .controlAccentColor
        textView.drawsBackground = false

        // --- Vertical growth + scrolling for long notes ---
        let bigDimension = CGFloat.greatestFiniteMagnitude
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: bigDimension, height: bigDimension)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.textContainer?.containerSize = NSSize(width: 0, height: bigDimension)

        // --- Comfortable writing ---
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4
        textView.defaultParagraphStyle = paragraph
        textView.typingAttributes = [
            .font: textView.font as Any,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraph,
        ]
        textView.isContinuousSpellCheckingEnabled = true
        textView.isGrammarCheckingEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.smartInsertDeleteEnabled = true

        // Load existing content, then strip baked-in text colors so it always
        // renders in the dynamic label color (fixes black-on-dark from old notes).
        let attributed = AttributedContent.attributedString(from: data)
        textView.textStorage?.setAttributedString(attributed)
        DeckTextView.makeReadable(textView.textStorage,
                                  in: NSRange(location: 0, length: textView.textStorage?.length ?? 0))

        context.coordinator.textView = textView
        controller?.textView = textView
        scrollView.documentView = textView
        context.coordinator.fitImages()
        // Focus the editor when a note opens, so it's immediately typeable (like Notes/Bear).
        DispatchQueue.main.async { [weak textView] in
            textView?.window?.makeFirstResponder(textView)
        }
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        // Selection changes rebuild the view (via .id), so nothing to sync here.
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        private let parent: RichTextEditor
        weak var textView: NSTextView?

        init(_ parent: RichTextEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            fitImages()
            guard let textStorage = textView?.textStorage else { return }
            parent.data = AttributedContent.data(from: textStorage)
        }

        /// Scales oversized inline images (pasted from Apple Notes, screenshots,
        /// etc.) down to the editor width so they read like a dream. Already-fitted
        /// attachments are skipped, so this is cheap to call on every change.
        func fitImages() {
            guard let tv = textView, let storage = tv.textStorage, storage.length > 0 else { return }
            let maxWidth = max(120, tv.bounds.width - tv.textContainerInset.width * 2 - 24)
            var changed = false
            storage.enumerateAttribute(.attachment,
                                       in: NSRange(location: 0, length: storage.length)) { value, _, _ in
                guard let attachment = value as? NSTextAttachment else { return }
                if attachment.bounds.width > 0 && attachment.bounds.width <= maxWidth { return }

                let intrinsic: CGSize
                if let image = attachment.image {
                    intrinsic = image.size
                } else if let data = attachment.fileWrapper?.regularFileContents,
                          let image = NSImage(data: data) {
                    intrinsic = image.size
                } else {
                    return
                }
                guard intrinsic.width > 0 else { return }

                if intrinsic.width > maxWidth {
                    let scale = maxWidth / intrinsic.width
                    attachment.bounds = CGRect(x: 0, y: 0, width: maxWidth, height: intrinsic.height * scale)
                    changed = true
                } else if attachment.bounds == .zero {
                    attachment.bounds = CGRect(origin: .zero, size: intrinsic)
                    changed = true
                }
            }
            if changed {
                tv.layoutManager?.invalidateDisplay(forCharacterRange: NSRange(location: 0, length: storage.length))
            }
        }
    }
}

/// NSTextView that always pastes clean, readable text.
///
/// By design, *every* paste behaves like "Paste and Match Style": incoming
/// fonts and colors are dropped and the text adopts the editor's own plain
/// style (dynamic label color, default font), so text copied from Apple Notes,
/// the web, etc. is never black-on-dark and never carries weird formatting.
/// Inline images are preserved. After each paste the typing style is reset, so
/// new typing — including after you delete everything — is always readable.
final class DeckTextView: NSTextView {
    override func paste(_ sender: Any?) {
        guard let storage = textStorage else { super.paste(sender); return }
        // Measure what got inserted by the change in document length — after paste,
        // NSTextView leaves the new text *selected at the original caret*, so we can't
        // rely on the selection moving forward to find the inserted range.
        let before = selectedRange()
        let lengthBefore = storage.length
        super.paste(sender)
        let inserted = storage.length - lengthBefore + before.length
        if inserted > 0 {
            normalizeToPlain(in: NSRange(location: before.location, length: inserted))
            didChangeText()
        }
        typingAttributes = defaultTypingAttributes()
    }

    override func pasteAsPlainText(_ sender: Any?) {
        // Insert with the clean style and keep typing clean afterwards.
        typingAttributes = defaultTypingAttributes()
        super.pasteAsPlainText(sender)
        typingAttributes = defaultTypingAttributes()
    }

    /// The editor's own plain style: default font, dynamic label color, default paragraph.
    func defaultTypingAttributes() -> [NSAttributedString.Key: Any] {
        let paragraph = (defaultParagraphStyle?.mutableCopy() as? NSMutableParagraphStyle) ?? {
            let p = NSMutableParagraphStyle(); p.lineSpacing = 4; return p
        }()
        return [
            .font: font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize + 1),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraph,
        ]
    }

    /// Replaces all text styling in `range` with the editor's plain style while
    /// keeping any inline image attachments intact.
    func normalizeToPlain(in range: NSRange) {
        guard let storage = textStorage, range.length > 0,
              range.location >= 0, range.location + range.length <= storage.length else { return }
        let defaults = defaultTypingAttributes()
        storage.beginEditing()
        storage.enumerateAttributes(in: range, options: []) { attrs, subRange, _ in
            if attrs[.attachment] is NSTextAttachment {
                storage.removeAttribute(.backgroundColor, range: subRange) // keep the image, drop stray highlight
            } else {
                storage.setAttributes(defaults, range: subRange)
            }
        }
        storage.endEditing()
    }

    /// Forces existing content to render in the dynamic label color (white on dark,
    /// black on light) so old notes with baked-in black text stay readable. NSTextView
    /// draws a run with *no* foreground color as pure black, so we set it explicitly.
    static func makeReadable(_ storage: NSTextStorage?, in range: NSRange) {
        guard let storage, range.length > 0,
              range.location >= 0, range.location + range.length <= storage.length else { return }
        storage.beginEditing()
        storage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: range)
        storage.removeAttribute(.backgroundColor, range: range)
        storage.endEditing()
    }

    // MARK: - Tiered bullet lists
    //
    // A bullet paragraph is marked by a leading "•\t" and an indent that grows
    // with its tier. Type "- " to start a list, Tab to nest deeper, Shift+Tab to
    // outdent, Return to continue (empty bullet outdents, then leaves the list).

    static let bulletMarker = "•\t"
    static let indentStep: CGFloat = 24
    static let markerIndent: CGFloat = 18

    /// Paragraph style for a bullet at `tier` (0 = top level), hanging-indented so
    /// wrapped lines align after the marker.
    static func bulletParagraphStyle(tier: Int, base: NSParagraphStyle?) -> NSMutableParagraphStyle {
        let p = (base?.mutableCopy() as? NSMutableParagraphStyle) ?? {
            let s = NSMutableParagraphStyle(); s.lineSpacing = 4; return s
        }()
        let lead = CGFloat(max(0, tier)) * indentStep
        p.firstLineHeadIndent = lead
        p.headIndent = lead + markerIndent
        p.defaultTabInterval = markerIndent
        p.tabStops = [NSTextTab(textAlignment: .left, location: lead + markerIndent)]
        return p
    }

    private func plainParagraphStyle() -> NSMutableParagraphStyle {
        (defaultParagraphStyle?.mutableCopy() as? NSMutableParagraphStyle) ?? {
            let s = NSMutableParagraphStyle(); s.lineSpacing = 4; return s
        }()
    }

    private func currentParagraphRange() -> NSRange {
        (string as NSString).paragraphRange(for: selectedRange())
    }

    private func isBulletParagraph(_ range: NSRange) -> Bool {
        (string as NSString).substring(with: range).hasPrefix(Self.bulletMarker)
    }

    private func tier(of range: NSRange) -> Int {
        guard let storage = textStorage, range.location < storage.length,
              let style = storage.attribute(.paragraphStyle, at: range.location,
                                            effectiveRange: nil) as? NSParagraphStyle
        else { return 0 }
        return max(0, Int((style.firstLineHeadIndent / Self.indentStep).rounded()))
    }

    /// Turn the selected paragraphs into a tier-0 list, or remove the list if they
    /// already are one. Backs the toolbar's bullet button.
    func toggleBulletList() {
        guard let storage = textStorage else { return }
        let para = currentParagraphRange()
        if isBulletParagraph(para) {
            removeBullet(in: para)
        } else {
            let marker = Self.bulletMarker as NSString
            guard shouldChangeText(in: NSRange(location: para.location, length: 0),
                                   replacementString: Self.bulletMarker) else { return }
            var attrs = typingAttributes
            let style = Self.bulletParagraphStyle(tier: 0, base: defaultParagraphStyle)
            attrs[.paragraphStyle] = style
            storage.insert(NSAttributedString(string: Self.bulletMarker, attributes: attrs),
                           at: para.location)
            let newPara = (string as NSString).paragraphRange(for: NSRange(location: para.location, length: 0))
            storage.addAttribute(.paragraphStyle, value: style, range: newPara)
            setSelectedRange(NSRange(location: para.location + marker.length, length: 0))
            typingAttributes[.paragraphStyle] = style
            didChangeText()
        }
    }

    override func insertText(_ insertString: Any, replacementRange: NSRange) {
        if let s = insertString as? String, s == " ", convertDashToBulletIfNeeded() { return }
        super.insertText(insertString, replacementRange: replacementRange)
    }

    override func insertTab(_ sender: Any?) {
        if adjustBulletTier(by: 1) { return }
        super.insertTab(sender)
    }

    override func insertBacktab(_ sender: Any?) {
        if adjustBulletTier(by: -1) { return }
        super.insertBacktab(sender)
    }

    override func insertNewline(_ sender: Any?) {
        guard let storage = textStorage else { super.insertNewline(sender); return }
        let para = currentParagraphRange()
        guard isBulletParagraph(para) else { super.insertNewline(sender); return }

        let markerLen = (Self.bulletMarker as NSString).length
        let text = (string as NSString).substring(with: para)
        let trimmed = text.hasSuffix("\n") ? String(text.dropLast()) : text
        if (trimmed as NSString).length <= markerLen {
            // Empty bullet: outdent one tier, or leave the list at tier 0.
            if tier(of: para) > 0 { adjustBulletTier(by: -1) } else { removeBullet(in: para) }
            return
        }

        let style = Self.bulletParagraphStyle(tier: tier(of: para), base: defaultParagraphStyle)
        var attrs = typingAttributes
        attrs[.paragraphStyle] = style
        let sel = selectedRange()
        let insertString = "\n" + Self.bulletMarker
        guard shouldChangeText(in: sel, replacementString: insertString) else { return }
        storage.replaceCharacters(in: sel, with: NSAttributedString(string: insertString, attributes: attrs))
        typingAttributes[.paragraphStyle] = style
        didChangeText()
    }

    override func deleteBackward(_ sender: Any?) {
        let sel = selectedRange()
        if sel.length == 0 {
            let para = currentParagraphRange()
            let markerLen = (Self.bulletMarker as NSString).length
            // Caret sits right in front of the words (just after "•\t"): one press
            // removes the whole marker — outdent a tier, or leave the list at tier 0.
            if isBulletParagraph(para), sel.location == para.location + markerLen {
                if tier(of: para) > 0 { adjustBulletTier(by: -1) } else { removeBullet(in: para) }
                return
            }
        }
        super.deleteBackward(sender)
    }

    /// If the caret follows a lone "-" at the start of a line, replace it with a
    /// bullet and consume the triggering space. Returns true if it handled it.
    private func convertDashToBulletIfNeeded() -> Bool {
        guard let storage = textStorage else { return false }
        let sel = selectedRange()
        guard sel.length == 0 else { return false }
        let ns = storage.string as NSString
        let para = ns.paragraphRange(for: sel)
        let prefix = ns.substring(with: NSRange(location: para.location, length: sel.location - para.location))
        guard prefix == "-" else { return false }

        let marker = Self.bulletMarker as NSString
        let dashRange = NSRange(location: para.location, length: 1)
        guard shouldChangeText(in: dashRange, replacementString: Self.bulletMarker) else { return false }
        let style = Self.bulletParagraphStyle(tier: 0, base: defaultParagraphStyle)
        var attrs = typingAttributes
        attrs[.paragraphStyle] = style
        storage.replaceCharacters(in: dashRange, with: NSAttributedString(string: Self.bulletMarker, attributes: attrs))
        let newPara = (storage.string as NSString).paragraphRange(for: NSRange(location: para.location, length: 0))
        storage.addAttribute(.paragraphStyle, value: style, range: newPara)
        setSelectedRange(NSRange(location: para.location + marker.length, length: 0))
        typingAttributes[.paragraphStyle] = style
        didChangeText()
        return true
    }

    /// Indent/outdent the current bullet paragraph by `delta` tiers. Outdenting past
    /// tier 0 removes the bullet. Returns false if the caret isn't in a bullet.
    @discardableResult
    private func adjustBulletTier(by delta: Int) -> Bool {
        guard let storage = textStorage else { return false }
        let para = currentParagraphRange()
        guard isBulletParagraph(para) else { return false }
        let newTier = tier(of: para) + delta
        if newTier < 0 { removeBullet(in: para); return true }
        let style = Self.bulletParagraphStyle(tier: min(newTier, 8), base: defaultParagraphStyle)
        guard shouldChangeText(in: para, replacementString: nil) else { return true }
        storage.addAttribute(.paragraphStyle, value: style, range: para)
        typingAttributes[.paragraphStyle] = style
        didChangeText()
        return true
    }

    /// Strip the "•\t" marker and reset the paragraph to the editor's plain style.
    private func removeBullet(in para: NSRange) {
        guard let storage = textStorage, isBulletParagraph(para) else { return }
        let markerRange = NSRange(location: para.location, length: (Self.bulletMarker as NSString).length)
        guard shouldChangeText(in: markerRange, replacementString: "") else { return }
        storage.replaceCharacters(in: markerRange, with: "")
        let style = plainParagraphStyle()
        let newPara = (string as NSString).paragraphRange(for: NSRange(location: para.location, length: 0))
        if newPara.length > 0 { storage.addAttribute(.paragraphStyle, value: style, range: newPara) }
        typingAttributes[.paragraphStyle] = style
        didChangeText()
    }
}
