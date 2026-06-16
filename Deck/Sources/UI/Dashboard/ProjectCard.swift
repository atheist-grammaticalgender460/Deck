import SwiftUI

struct ProjectCard: View {
    let project: Project
    let theme: CategoryTheme

    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            counts
            Divider().opacity(0.6)
            typeBreakdown
        }
        .padding(DeckMetrics.cardPadding)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .glassEffect(.regular.tint(theme.glassTint),
                     in: .rect(cornerRadius: DeckMetrics.cardRadius))
        .contentShape(.rect(cornerRadius: DeckMetrics.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DeckMetrics.cardRadius)
                .strokeBorder(theme.color.opacity(hovering ? 0.45 : 0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(hovering ? 0.18 : 0.08),
                radius: hovering ? 12 : 6, y: hovering ? 5 : 2)
        .scaleEffect(hovering ? 1.012 : 1)
        .animation(.easeOut(duration: 0.16), value: hovering)
        .onHover { hovering = $0 }
    }

    private var header: some View {
        HStack(spacing: 9) {
            Text(project.emoji ?? "📁")
                .font(.title2)
            Text(project.name)
                .font(.headline)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }

    private var counts: some View {
        HStack(spacing: 18) {
            stat(project.pendingCount, "pending", color: theme.color)
            stat(project.doneCount, "done", color: .secondary)
        }
    }

    private func stat(_ value: Int, _ label: String, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text("\(value)")
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var typeBreakdown: some View {
        HStack(spacing: 14) {
            ForEach(ItemType.allCases) { type in
                let c = project.counts(for: type)
                Label {
                    Text("\(c.pending)/\(c.pending + c.done)")
                        .font(.caption.monospacedDigit())
                } icon: {
                    Image(systemName: type.symbol)
                        .foregroundStyle(type.tint)
                }
                .font(.caption)
                .help("\(type.label): \(c.pending) open · \(c.done) done")
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.secondary)
    }
}
