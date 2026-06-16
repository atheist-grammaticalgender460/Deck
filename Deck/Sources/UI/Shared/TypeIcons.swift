import SwiftUI

/// A note's type, always in a FIXED-WIDTH slot so every row aligns regardless of
/// whether the note is a bug, a feature, or both. Bug+feature gets its own badge.
struct TypeIcons: View {
    let note: Note
    var size: CGFloat = 22

    var body: some View {
        Group {
            if note.isBug && note.isFeature {
                CombinedTypeBadge()
            } else if note.isBug {
                Image(systemName: ItemType.bug.symbol).foregroundStyle(ItemType.bug.tint)
            } else {
                Image(systemName: ItemType.feature.symbol).foregroundStyle(ItemType.feature.tint)
            }
        }
        .frame(width: size, alignment: .center)
    }
}

/// A single mark for "bug + feature": a two-tone rounded tag carrying both glyphs.
struct CombinedTypeBadge: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(
                LinearGradient(colors: [ItemType.bug.tint, ItemType.feature.tint],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .frame(width: 18, height: 18)
            .overlay(
                Image(systemName: "plus")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
            )
            .shadow(color: .black.opacity(0.2), radius: 1, y: 0.5)
    }
}
