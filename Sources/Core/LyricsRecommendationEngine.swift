import Foundation

struct LyricsRecommendationEngine {
    static let rules: [RecommendationRule] = [
        SyncedLyricsRule(),
        DurationRule(),
        TitleMatchRule(),
        ArtistMatchRule()
    ]
    
    static func findBestMatch(in results: [LRCLIBResponse], forDuration duration: Double, expectedTitle: String, expectedArtist: String) -> LRCLIBResponse? {
        let context = RecommendationContext(duration: duration, expectedTitle: expectedTitle, expectedArtist: expectedArtist)
        
        // 1. Filter out results that have no lyrics at all
        var validResults = results.filter { $0.syncedLyrics != nil || $0.plainLyrics != nil }
        
        // 2. Hard filter out results where the duration difference > 10s (if track duration is > 0)
        if duration > 0 {
            validResults = validResults.filter { response in
                guard let rd = response.duration else { return true } // keep if no duration known
                return abs(rd - duration) <= 10.0
            }
        }
        
        // 3. Score the remaining candidates
        let scoredCandidates = validResults.map { response -> (LRCLIBResponse, Int) in
            let score = rules.reduce(0) { total, rule in
                total + rule.score(for: response, context: context)
            }
            return (response, score)
        }
        
        // 4. Return the candidate with the highest score
        return scoredCandidates.max(by: { $0.1 < $1.1 })?.0
    }
}
