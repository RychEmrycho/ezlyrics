import Foundation

struct FetchResult {
    let lyrics: ParsedLyrics
    let recommendedResult: SearchResult?
    let searchQuery: String
}

struct RecommendationContext: Sendable {
    let duration: Double
    let expectedTitle: String
    let expectedArtist: String
}

protocol RecommendationRule: Sendable {
    func score(for result: SearchResult, context: RecommendationContext) -> Int
}

struct SyncedLyricsRule: RecommendationRule {
    func score(for result: SearchResult, context: RecommendationContext) -> Int {
        if result.syncedLyrics != nil {
            return 100
        } else if result.plainLyrics != nil {
            return 10
        }
        return 0
    }
}

struct DurationRule: RecommendationRule {
    func score(for result: SearchResult, context: RecommendationContext) -> Int {
        guard context.duration > 0, let resultDuration = result.duration else {
            return 0
        }
        
        let diff = abs(resultDuration - context.duration)
        return -Int(diff)
    }
}

struct TitleMatchRule: RecommendationRule {
    func score(for result: SearchResult, context: RecommendationContext) -> Int {
        let expectedTitle = context.expectedTitle.lowercased()
        let responseTitle = result.trackName.lowercased()
        
        if expectedTitle == responseTitle {
            return 20
        } else if responseTitle.contains(expectedTitle) || expectedTitle.contains(responseTitle) {
            return 5
        }
        return 0
    }
}

struct ArtistMatchRule: RecommendationRule {
    func score(for result: SearchResult, context: RecommendationContext) -> Int {
        let expectedArtist = context.expectedArtist.lowercased()
        let responseArtist = result.artistName.lowercased()
        
        if expectedArtist == responseArtist {
            return 30
        } else if responseArtist.contains(expectedArtist) || expectedArtist.contains(responseArtist) {
            return 10
        }
        return 0
    }
}
