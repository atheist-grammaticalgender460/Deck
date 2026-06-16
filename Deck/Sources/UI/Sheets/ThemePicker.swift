import SwiftUI

/// A swatch grid for choosing a category theme color.
struct ThemePicker: View {
    @Binding var theme: CategoryTheme

    private let columns = [GridItem(.adaptive(minimum: 36), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(CategoryTheme.allCases) { option in
                Circle()
                    .fill(option.color)
                    .frame(width: 30, height: 30)
                    .overlay {
                        if theme == option {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .overlay(
                        Circle().strokeBorder(.primary.opacity(theme == option ? 0.85 : 0), lineWidth: 2.5)
                            .padding(-3)
                    )
                    .contentShape(Circle())
                    .onTapGesture { theme = option }
                    .help(option.label)
            }
        }
    }
}
