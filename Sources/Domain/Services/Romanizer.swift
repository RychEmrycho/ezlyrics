import Foundation

public protocol StringTransliterator {
    func toLatin(_ text: String) -> String?
    func stripCombiningMarks(_ text: String) -> String?
}

public struct FoundationStringTransliterator: StringTransliterator {
    public init() {}
    
    public func toLatin(_ text: String) -> String? {
        return text.applyingTransform(.toLatin, reverse: false)
    }
    
    public func stripCombiningMarks(_ text: String) -> String? {
        return text.applyingTransform(.stripCombiningMarks, reverse: false)
    }
}

struct Romanizer {
    private let transliterator: StringTransliterator
    
    init(transliterator: StringTransliterator = FoundationStringTransliterator()) {
        self.transliterator = transliterator
    }
    
    /// Converts CJK/non-Latin text to Latin phonetic representation.
    /// Returns nil if the text is already Latin or transform produces no change.
    func romanize(_ text: String) -> String? {
        guard !text.isEmpty else { return nil }
        
        guard let latinized = transliterator.toLatin(text) else {
            return nil
        }
        
        // Strip diacritics for cleaner output (e.g. ā → a, è → e)
        let result = transliterator.stripCombiningMarks(latinized) ?? latinized
        
        // Return nil if the text was already Latin (no meaningful change)
        guard result.trimmingCharacters(in: .whitespaces) != text.trimmingCharacters(in: .whitespaces) else {
            return nil
        }
        
        return result
    }
}
