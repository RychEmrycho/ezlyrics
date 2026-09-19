import Foundation

/// Concrete implementation of LyricsRepository backed by LRCLIB.
/// This is the only class that knows about both LRCLIBClient and domain types.
@MainActor
final class LyricsRepositoryImpl: LyricsRepository {
    
    private let client: LRCLIBClient
    private let cache: LyricsCacheProtocol
    
    nonisolated init(client: LRCLIBClient, cache: LyricsCacheProtocol) {
        self.client = client
        self.cache = cache
    }
    
    nonisolated func fetchBestLyrics(for track: Track) async -> FetchResult {
        if let cached = await cache.getCachedLyrics(artist: track.artist, title: track.title) {
            return FetchResult(
                lyrics: cached,
                recommendedResult: SearchResult(
                    id: cached.sourceID ?? -1,
                    trackName: cached.trackName,
                    artistName: cached.artistName,
                    albumName: nil,
                    duration: nil,
                    instrumental: false,
                    plainLyrics: nil,
                    syncedLyrics: cached.isSynced ? "cached" : nil
                ),
                searchQuery: "\(track.artist) \(track.title)"
            )
        }
        
        do {
            let response = try await client.getLyrics(artist: track.artist, title: track.title, duration: track.duration)
            let searchResult = response.toSearchResult()
            let parsed = LyricsParser.parse(plain: response.plainLyrics, synced: response.syncedLyrics, trackName: response.trackName, artistName: response.artistName, sourceID: response.id)
            await cache.cache(lyrics: parsed, artist: track.artist, title: track.title)
            
            return FetchResult(
                lyrics: parsed,
                recommendedResult: response.syncedLyrics != nil ? searchResult : nil,
                searchQuery: "\(track.artist) \(track.title)"
            )
        } catch {
            do {
                let responses = try await client.searchLyrics(query: track.title)
                let results = responses.map { $0.toSearchResult() }
                
                if let bestMatch = LyricsRecommendationEngine.findBestMatch(in: results, forDuration: track.duration, expectedTitle: track.title, expectedArtist: track.artist) {
                    let parsed = LyricsParser.parse(plain: bestMatch.plainLyrics, synced: bestMatch.syncedLyrics, trackName: bestMatch.trackName, artistName: bestMatch.artistName, sourceID: bestMatch.id)
                    await cache.cache(lyrics: parsed, artist: track.artist, title: track.title)
                    
                    return FetchResult(
                        lyrics: parsed,
                        recommendedResult: bestMatch.syncedLyrics != nil ? bestMatch : nil,
                        searchQuery: track.title
                    )
                } else {
                    AppLogger.lyrics.warning("Failed to fetch lyrics: No lyrics found in search results.")
                    return createEmptyResult(for: track)
                }
            } catch {
                AppLogger.lyrics.error("Failed to fetch lyrics via search: \(error)")
                return createEmptyResult(for: track)
            }
        }
    }
    
    nonisolated func searchLyrics(query: String) async throws -> [SearchResult] {
        let responses = try await client.searchLyrics(query: query)
        return responses.map { $0.toSearchResult() }
    }
    
    nonisolated func applyOverride(_ result: SearchResult, for track: Track) async -> ParsedLyrics {
        let parsed = LyricsParser.parse(plain: result.plainLyrics, synced: result.syncedLyrics, trackName: result.trackName, artistName: result.artistName, sourceID: result.id)
        await cache.cache(lyrics: parsed, artist: track.artist, title: track.title)
        return parsed
    }
    
    private nonisolated func createEmptyResult(for track: Track) -> FetchResult {
        return FetchResult(
            lyrics: ParsedLyrics(trackName: track.title, artistName: track.artist, isSynced: false, lines: [], detectedLanguage: nil),
            recommendedResult: nil,
            searchQuery: "\(track.artist) \(track.title)"
        )
    }
}
