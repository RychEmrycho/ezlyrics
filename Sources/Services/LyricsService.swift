import Foundation

@MainActor
class LyricsService {
    static let shared = LyricsService()
    
    private init() {}
    
    func fetchBestLyrics(for track: NowPlayingTrack) async -> FetchResult {
        if let cached = LyricsCache.shared.getCachedLyrics(artist: track.artist, title: track.title) {
            return FetchResult(
                lyrics: cached,
                recommendedResponse: cached.originalResponse,
                searchQuery: "\(track.artist) \(track.title)"
            )
        }
        
        do {
            let response = try await LRCLIBClient.shared.getLyrics(artist: track.artist, title: track.title, duration: track.duration)
            let parsed = LRCParser.parse(plain: response.plainLyrics, synced: response.syncedLyrics, trackName: response.trackName, artistName: response.artistName, sourceID: response.id, originalResponse: response)
            LyricsCache.shared.cache(lyrics: parsed, artist: track.artist, title: track.title)
            
            return FetchResult(
                lyrics: parsed,
                recommendedResponse: response.syncedLyrics != nil ? response : nil,
                searchQuery: "\(track.artist) \(track.title)"
            )
        } catch {
            do {
                let results = try await LRCLIBClient.shared.searchLyrics(query: track.title)
                
                if let bestMatch = LyricsRecommendationEngine.findBestMatch(in: results, forDuration: track.duration, expectedTitle: track.title, expectedArtist: track.artist) {
                    let parsed = LRCParser.parse(plain: bestMatch.plainLyrics, synced: bestMatch.syncedLyrics, trackName: bestMatch.trackName, artistName: bestMatch.artistName, sourceID: bestMatch.id, originalResponse: bestMatch)
                    LyricsCache.shared.cache(lyrics: parsed, artist: track.artist, title: track.title)
                    
                    return FetchResult(
                        lyrics: parsed,
                        recommendedResponse: bestMatch.syncedLyrics != nil ? bestMatch : nil,
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
            recommendedResponse: nil,
            searchQuery: "\(track.artist) \(track.title)"
        )
    }
}
