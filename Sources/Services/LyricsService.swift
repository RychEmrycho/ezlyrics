import Foundation

@MainActor
class LyricsService {
    static let shared = LyricsService()
    
    private init() {}
    var availableProviders: [LyricProvider] = [LRCLIBClient.shared, OvhLyricsClient.shared]
    
    var activeProvider: LyricProvider {
        let selected = UserPreferences.shared.lyricProvider
        return availableProviders.first(where: { $0.name == selected }) ?? availableProviders.first!
    }
    
    func searchLyrics(query: String) async throws -> [LyricSearchResult] {
        let provider = activeProvider
        do {
            return try await provider.searchLyrics(query: query)
        } catch {
            print("Provider \(provider.name) search failed: \(error)")
            return []
        }
    }
    
    func fetchLyrics(for searchResult: LyricSearchResult) async throws -> ParsedLyrics {
        if let provider = availableProviders.first(where: { $0.name == searchResult.providerName }) {
            return try await provider.fetchLyrics(for: searchResult)
        }
        throw NSError(domain: "LyricsService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Provider not found"])
    }
    
    func fetchBestLyrics(for track: NowPlayingTrack) async -> FetchResult {
        if let cached = LyricsCache.shared.getCachedLyrics(artist: track.artist, title: track.title) {
            return FetchResult(
                lyrics: cached,
                recommendedResponse: cached.originalResponse,
                searchQuery: "\(track.artist) \(track.title)"
            )
        }
        
        let provider = activeProvider
        do {
            // Try to get exact match
            let parsed = try await provider.getLyrics(artist: track.artist, title: track.title, duration: track.duration)
            LyricsCache.shared.cache(lyrics: parsed, artist: track.artist, title: track.title)
            
            return FetchResult(
                lyrics: parsed,
                recommendedResponse: nil, // If it's an exact match, we don't necessarily have a search result to recommend
                searchQuery: "\(track.artist) \(track.title)"
            )
        } catch {
            print("Provider \(provider.name) exact match failed: \(error)")
            do {
                // Fallback to search using the same provider
                let results = try await provider.searchLyrics(query: track.title)
                if let bestMatch = LyricsRecommendationEngine.findBestMatch(in: results, forDuration: track.duration, expectedTitle: track.title, expectedArtist: track.artist) {
                    let parsed = try await provider.fetchLyrics(for: bestMatch)
                    LyricsCache.shared.cache(lyrics: parsed, artist: track.artist, title: track.title)
                    
                    return FetchResult(
                        lyrics: parsed,
                        recommendedResponse: bestMatch,
                        searchQuery: track.title
                    )
                }
            } catch {
                print("Provider \(provider.name) search match failed: \(error)")
            }
        }
        
        // If all providers fail
        return createEmptyResult(for: track)
    }
    
    private func createEmptyResult(for track: NowPlayingTrack) -> FetchResult {
        return FetchResult(
            lyrics: ParsedLyrics(trackName: track.title, artistName: track.artist, isSynced: false, lines: [], detectedLanguage: nil),
            recommendedResponse: nil,
            searchQuery: "\(track.artist) \(track.title)"
        )
    }
}
