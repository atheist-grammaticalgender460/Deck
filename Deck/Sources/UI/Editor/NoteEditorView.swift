import SwiftData
import SwiftUI

struct NoteEditorView: View {
    @Bindable var note: Note
    var theme: CategoryTheme = .blue

    @Environment(\.modelContext) private var context
    @StateObject private var controller = RichTextController()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            formattingBar
            RichTextEditor(
                data: Binding(
                    get: { note.contentRTFD },
                    set: { newValue in
                        note.contentRTFD = newValue
                        note.updatedAt = Date()
                    }
                ),
                controller: controller
            )
            .softScrollEdges()
        }
        .background(.clear)
        .onChange(of: note.contentRTFD) { _, newValue in
            // Auto-title from the first line (like Apple Notes) while the title is
            // blank — makes pasting an old note in title itself with no extra step.
            if note.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let line = AttributedContent.firstLine(from: newValue)
                if !line.isEmpty { note.title = line }
            }
            save()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Title", text: $note.title)
                .textFieldStyle(.plain)
                .font(.title.bold())
                .onChange(of: note.title) { _, _ in
                    note.updatedAt = Date(); save()
                }

            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    ForEach(ItemType.allCases) { type in
                        typeToggle(type)
                    }
                }

                Toggle("Done", isOn: Binding(
                    get: { note.status == .done },
                    set: { on in note.setStatus(on ? .done : .pending); save() }
                ))
                .toggleStyle(.switch)
                .tint(theme.color)
                .fixedSize()

                Spacer()

                Text(note.updatedAt, format: .dateTime.month().day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    /// A Bug/Feature pill that toggles independently — a note can be both.
    private func typeToggle(_ type: ItemType) -> some View {
        let on = note.has(type)
        return Button {
            if on && note.activeTypeCount <= 1 { return } // keep at least one
            note.set(type, !on)
            note.updatedAt = Date()
            save()
        } label: {
            Label(type.label, systemImage: type.symbol)
                .font(.callout)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(on ? type.tint.opacity(0.22) : Color.clear, in: Capsule())
                .overlay(Capsule().strokeBorder(on ? type.tint.opacity(0.7) : .secondary.opacity(0.35)))
                .foregroundStyle(on ? type.tint : .secondary)
        }
        .buttonStyle(.plain)
        .fixedSize()
    }

    /// Formatting control strip — Liquid Glass buttons on the navigation layer.
    private var formattingBar: some View {
        HStack(spacing: 8) {
            GlassEffectContainer(spacing: 6) {
                HStack(spacing: 6) {
                    toolButton("bold", help: "Bold (⌘B)") { controller.toggleBold() }
                        .keyboardShortcut("b", modifiers: .command)
                    toolButton("italic", help: "Italic (⌘I)") { controller.toggleItalic() }
                        .keyboardShortcut("i", modifiers: .command)
                    toolButton("list.bullet", help: "Bulleted list") { controller.toggleBullets() }
                    toolButton("photo", help: "Insert image") { controller.insertImage() }
                }
            }

            Spacer()

            GlassEffectContainer(spacing: 6) {
                HStack(spacing: 6) {
                    toolButton("doc.on.doc", help: "Copy with formatting") { controller.copyAll() }
                    Menu {
                        Button("Export as PDF…") { controller.exportPDF(suggestedName: note.title) }
                        Button("Export as RTFD…") { controller.exportRTFD(suggestedName: note.title) }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(theme.color)
                            .frame(width: 32, height: 32)
                    }
                    .menuStyle(.button)
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .help("Export")
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) { Divider() }
    }

    private func toolButton(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(theme.color)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .help(help)
    }

    private func save() {
        try? context.save()
    }
}
