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

struct ParsedLyrics: Equatable, Codable {
    let trackName: String
    let artistName: String
    let isSynced: Bool
    let lines: [LyricLine]
    var detectedLanguage: String? = nil
    var sourceID: String? = nil
    var originalResponse: LyricSearchResult? = nil
}

struct FetchResult {
    let lyrics: ParsedLyrics
    let recommendedResponse: LyricSearchResult?
    let searchQuery: String
}

struct RecommendationContext: Sendable {
    let duration: Double
    let expectedTitle: String
    let expectedArtist: String
}

protocol RecommendationRule: Sendable {
    func score(for response: LyricSearchResult, context: RecommendationContext) -> Int
}

struct SyncedLyricsRule: RecommendationRule {
    func score(for response: LyricSearchResult, context: RecommendationContext) -> Int {
        if response.hasSyncedLyrics {
            return 100
        } else if response.hasPlainLyrics {
            return 10
        }
        return 0
    }
}

struct DurationRule: RecommendationRule {
    func score(for response: LyricSearchResult, context: RecommendationContext) -> Int {
        guard context.duration > 0, let responseDuration = response.duration else {
            return 0
        }
        
        let diff = abs(responseDuration - context.duration)
        return -Int(diff)
    }
}

struct TitleMatchRule: RecommendationRule {
    func score(for response: LyricSearchResult, context: RecommendationContext) -> Int {
        let expectedTitle = context.expectedTitle.lowercased()
        let responseTitle = response.trackName.lowercased()
        
        if expectedTitle == responseTitle {
            return 20
        } else if responseTitle.contains(expectedTitle) || expectedTitle.contains(responseTitle) {
            return 5
        }
        return 0
    }
}

struct ArtistMatchRule: RecommendationRule {
    func score(for response: LyricSearchResult, context: RecommendationContext) -> Int {
        let expectedArtist = context.expectedArtist.lowercased()
        let responseArtist = response.artistName.lowercased()
        
        if expectedArtist == responseArtist {
            return 30
        } else if responseArtist.contains(expectedArtist) || expectedArtist.contains(responseArtist) {
            return 10
        }
        return 0
    }
}
