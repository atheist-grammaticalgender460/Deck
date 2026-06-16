import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Suggests a fitting emoji for a project name using on-device Apple Intelligence
/// (Foundation Models). Returns nil when the model isn't available — callers fall
/// back to a manual emoji or the default folder glyph.
enum EmojiSuggester {

    /// True when on-device generation is usable on this Mac.
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(macOS 26, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
        }
        #endif
        return false
    }

    static func suggest(for name: String) async -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        #if canImport(FoundationModels)
        if #available(macOS 26, *) {
            guard case .available = SystemLanguageModel.default.availability else { return nil }
            do {
                let session = LanguageModelSession(
                    instructions: "You reply with exactly one emoji and nothing else — no words, no punctuation."
                )
                let prompt = "Pick the single best emoji to represent a software project named \"\(trimmed)\"."
                let response = try await session.respond(to: prompt)
                return firstEmoji(in: response.content)
            } catch {
                return nil
            }
        }
        #endif
        return nil
    }

    /// Extracts the first real emoji character (ignoring plain digits/symbols).
    static func firstEmoji(in text: String) -> String? {
        for character in text {
            let scalars = character.unicodeScalars
            let isEmoji = scalars.contains { $0.properties.isEmoji && $0.value > 0x238C }
            if isEmoji { return String(character) }
        }
        return nil
    }
}
