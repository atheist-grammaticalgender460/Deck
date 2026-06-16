import SwiftUI

struct NoteRow: View {
    let note: Note
    var tint: Color = .accentColor
    var isSelected: Bool = false

    @State private var hovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            TypeIcons(note: note)
                .font(.body)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.headline)
                    .lineLimit(1)
                    .strikethrough(note.status == .done, color: .secondary)
                    .foregroundStyle(note.status == .done ? .secondary : .primary)

                HStack(spacing: 6) {
                    Text(note.updatedAt, format: .dateTime.month().day())
                        .foregroundStyle(.secondary)
                    let snippet = AttributedContent.snippet(from: note.contentRTFD)
                    if !snippet.isEmpty {
                        Text(snippet)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
                .font(.subheadline)
            }

            Spacer(minLength: 4)

            if note.status == .done {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .padding(.top, 2)
                    .symbolEffect(.bounce, value: note.status)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? AnyShapeStyle(tint.opacity(0.18))
                      : (hovering ? AnyShapeStyle(Color.primary.opacity(0.05)) : AnyShapeStyle(Color.clear)))
        )
        .onHover { hovering = $0 }
        .overlay(alignment: .leading) {
            if isSelected {
                Capsule()
                    .fill(tint)
                    .frame(width: 3)
                    .padding(.vertical, 6)
            }
        }
    }
}
