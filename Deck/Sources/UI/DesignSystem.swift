import SwiftUI

/// Per-category glass theme. The color is used three ways, in increasing intensity:
/// 1. As a whisper-light glass tint on project cards (legibility-safe).
/// 2. As the selection / accent color in the sidebar and note list.
/// 3. As a saturated dot/glyph for at-a-glance identification.
enum CategoryTheme: String, CaseIterable, Identifiable {
    case blue, cyan, teal, mint, green, yellow, orange, red, pink, purple, indigo, brown, graphite

    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    /// Full-strength identity color (dots, selection, accents).
    var color: Color {
        switch self {
        case .blue:     return Color(red: 0.20, green: 0.52, blue: 0.96)
        case .cyan:     return Color(red: 0.20, green: 0.74, blue: 0.90)
        case .teal:     return Color(red: 0.10, green: 0.65, blue: 0.62)
        case .mint:     return Color(red: 0.24, green: 0.80, blue: 0.62)
        case .green:    return Color(red: 0.20, green: 0.70, blue: 0.42)
        case .yellow:   return Color(red: 0.92, green: 0.76, blue: 0.22)
        case .orange:   return Color(red: 0.96, green: 0.58, blue: 0.18)
        case .red:      return Color(red: 0.94, green: 0.27, blue: 0.30)
        case .pink:     return Color(red: 0.96, green: 0.36, blue: 0.62)
        case .purple:   return Color(red: 0.58, green: 0.40, blue: 0.92)
        case .indigo:   return Color(red: 0.36, green: 0.34, blue: 0.84)
        case .brown:    return Color(red: 0.60, green: 0.46, blue: 0.32)
        case .graphite: return Color(red: 0.45, green: 0.48, blue: 0.55)
        }
    }

    /// Legibility-safe tint for a glass surface that sits behind text.
    var glassTint: Color { color.opacity(0.16) }
}

extension View {
    /// Material blur fade at the BOTTOM edge of a scroll area. Pairs with the
    /// system `.scrollEdgeEffectStyle` (which blurs the TOP under the toolbar)
    /// so content melts into the chrome at both ends.
    func bottomScrollFade(_ height: CGFloat = 44) -> some View {
        overlay(alignment: .bottom) { edgeFade(height: height, top: false) }
    }

    /// Both top and bottom material fades — for the rich-text editor, which is an
    /// AppKit scroll view and can't use `.scrollEdgeEffectStyle`.
    func softScrollEdges(_ height: CGFloat = 44) -> some View {
        overlay(alignment: .top) { edgeFade(height: height, top: true) }
            .overlay(alignment: .bottom) { edgeFade(height: height, top: false) }
    }

    private func edgeFade(height: CGFloat, top: Bool) -> some View {
        Rectangle()
            .fill(.thinMaterial)
            .frame(height: height)
            .mask(
                LinearGradient(
                    stops: top
                        ? [.init(color: .black, location: 0), .init(color: .clear, location: 1)]
                        : [.init(color: .clear, location: 0), .init(color: .black, location: 1)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .allowsHitTesting(false)
    }
}

/// Shared metrics so cards, rows, and panes stay visually consistent.
enum DeckMetrics {
    static let cardRadius: CGFloat = 18
    static let controlRadius: CGFloat = 12
    static let cardPadding: CGFloat = 16
    static let gridSpacing: CGFloat = 16
    static let windowMargin: CGFloat = 20
}
