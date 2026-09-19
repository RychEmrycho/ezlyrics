import Foundation

struct ParsedLyrics: Equatable, Codable {
    let trackName: String
    let artistName: String
    let isSynced: Bool
    let lines: [LyricLine]
    var detectedLanguage: String? = nil
    var sourceID: Int? = nil
}
