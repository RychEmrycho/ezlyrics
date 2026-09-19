import Foundation

protocol TranslatableItem: Identifiable {
    var id: UUID { get }
    var translatableText: String { get }
}

extension LyricLine: TranslatableItem {
    var translatableText: String {
        return text
    }
    
    var isTranslatable: Bool {
        return !text.isEmpty && text != "•••" && text != "♫"
    }
}
