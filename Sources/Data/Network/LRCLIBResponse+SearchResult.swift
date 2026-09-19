import Foundation

/// Maps the provider-specific DTO to the domain's provider-agnostic SearchResult.
extension LRCLIBResponse {
    func toSearchResult() -> SearchResult {
        SearchResult(
            id: id,
            trackName: trackName,
            artistName: artistName,
            albumName: albumName,
            duration: duration,
            instrumental: instrumental,
            plainLyrics: plainLyrics,
            syncedLyrics: syncedLyrics
        )
    }
}
