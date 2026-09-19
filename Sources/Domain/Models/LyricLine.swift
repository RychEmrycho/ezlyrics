import Foundation

struct Syllable: Identifiable, Equatable, Codable {
    var id = UUID()
    let timestamp: TimeInterval
    let text: String
}

struct LyricLine: Identifiable, Equatable, Codable {
    var id = UUID()
    let timestamp: TimeInterval
    let text: String
    let syllables: [Syllable]?
}
