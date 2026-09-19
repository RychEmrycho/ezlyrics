import Foundation

struct Romanizer {
    /// Converts CJK/non-Latin text to Latin phonetic representation.
    /// Uses Swift's native `applyingTransform(.toLatin)` backed by ICU.
    /// Returns nil if the text is already Latin or transform produces no change.
    static func romanize(_ text: String) -> String? {
        guard !text.isEmpty else { return nil }
        
        guard let latinized = text.applyingTransform(.toLatin, reverse: false) else {
            return nil
        }
        
        // Strip diacritics for cleaner output (e.g. ā → a, è → e)
        let result = latinized.applyingTransform(.stripCombiningMarks, reverse: false) ?? latinized
        
        // Return nil if the text was already Latin (no meaningful change)
        guard result.trimmingCharacters(in: .whitespaces) != text.trimmingCharacters(in: .whitespaces) else {
            return nil
        }
        
        return result
    }
}
