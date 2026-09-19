import Foundation

struct LyricsRecommendationEngine {
    static let rules: [RecommendationRule] = [
        SyncedLyricsRule(),
        DurationRule(),
        TitleMatchRule(),
        ArtistMatchRule()
    ]
    
    static func findBestMatch(in results: [SearchResult], forDuration duration: Double, expectedTitle: String, expectedArtist: String) -> SearchResult? {
        let context = RecommendationContext(duration: duration, expectedTitle: expectedTitle, expectedArtist: expectedArtist)
        
        // 1. Filter out results that have no lyrics at all
        var validResults = results.filter { $0.syncedLyrics != nil || $0.plainLyrics != nil }
        
        // 2. Hard filter out results where the duration difference > 10s (if track duration is > 0)
        if duration > 0 {
            validResults = validResults.filter { result in
                guard let rd = result.duration else { return true } // keep if no duration known
                return abs(rd - duration) <= 10.0
            }
        }
        
        // 3. Score the remaining candidates
        let scoredCandidates = validResults.map { result -> (SearchResult, Int) in
            let score = rules.reduce(0) { total, rule in
                total + rule.score(for: result, context: context)
            }
            return (result, score)
        }
        
        // 4. Return the candidate with the highest score
        return scoredCandidates.max(by: { $0.1 < $1.1 })?.0
    }
}
