import Foundation

struct FetchResult {
    let lyrics: ParsedLyrics
    let suggestedResponse: LRCLIBResponse?
    let searchQuery: String
}

@MainActor
class LyricsService {
    static let shared = LyricsService()
    
    private init() {}
    
    func fetchBestLyrics(for track: NowPlayingTrack) async -> FetchResult {
        if let cached = LyricsCache.shared.getCachedLyrics(artist: track.artist, title: track.title) {
            return FetchResult(
                lyrics: cached,
                suggestedResponse: cached.originalResponse,
                searchQuery: "\(track.artist) \(track.title)"
            )
        }
        
        do {
            let response = try await LRCLIBClient.shared.getLyrics(artist: track.artist, title: track.title, duration: track.duration)
            let parsed = LRCParser.parse(plain: response.plainLyrics, synced: response.syncedLyrics, trackName: response.trackName, artistName: response.artistName, sourceID: response.id, originalResponse: response)
            LyricsCache.shared.cache(lyrics: parsed, artist: track.artist, title: track.title)
            
            return FetchResult(
                lyrics: parsed,
                suggestedResponse: response.syncedLyrics != nil ? response : nil,
                searchQuery: "\(track.artist) \(track.title)"
            )
        } catch {
            do {
                let results = try await LRCLIBClient.shared.searchLyrics(query: track.title)
                
                var bestSuggested: LRCLIBResponse? = nil
                let syncedResults = results.filter { $0.syncedLyrics != nil }
                
                if track.duration > 0 && !syncedResults.isEmpty {
                    bestSuggested = syncedResults.min(by: { 
                        let d1 = $0.duration ?? 0
                        let d2 = $1.duration ?? 0
                        return abs(d1 - track.duration) < abs(d2 - track.duration)
                    })
                    // Must be within 10 seconds to be considered a "close duration" suggestion
                    if let bs = bestSuggested, let d = bs.duration, abs(d - track.duration) > 10.0 {
                        bestSuggested = nil
                    }
                } else if !syncedResults.isEmpty {
                    bestSuggested = syncedResults.first
                }
                
                let fallbackMatch = results.first(where: { $0.syncedLyrics != nil || $0.plainLyrics != nil })
                
                if let bestMatch = bestSuggested ?? fallbackMatch {
                    let parsed = LRCParser.parse(plain: bestMatch.plainLyrics, synced: bestMatch.syncedLyrics, trackName: bestMatch.trackName, artistName: bestMatch.artistName, sourceID: bestMatch.id, originalResponse: bestMatch)
                    LyricsCache.shared.cache(lyrics: parsed, artist: track.artist, title: track.title)
                    
                    return FetchResult(
                        lyrics: parsed,
                        suggestedResponse: bestMatch.syncedLyrics != nil ? bestMatch : nil,
                        searchQuery: track.title
                    )
                } else {
                    print("Failed to fetch lyrics: No lyrics found in search results.")
                    return createEmptyResult(for: track)
                }
            } catch {
                print("Failed to fetch lyrics via search: \(error)")
                return createEmptyResult(for: track)
            }
        }
    }
    
    private func createEmptyResult(for track: NowPlayingTrack) -> FetchResult {
        return FetchResult(
            lyrics: ParsedLyrics(trackName: track.title, artistName: track.artist, isSynced: false, lines: [], detectedLanguage: nil),
            suggestedResponse: nil,
            searchQuery: "\(track.artist) \(track.title)"
        )
    }
}
