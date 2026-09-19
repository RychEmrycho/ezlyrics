import Foundation

/// Abstracts lyrics fetching and search operations.
/// The data layer provides concrete implementations backed by specific providers.
protocol LyricsRepository: Sendable {
    func fetchBestLyrics(for track: Track) async -> FetchResult
    func searchLyrics(query: String) async throws -> [SearchResult]
    func applyOverride(_ result: SearchResult, for track: Track) async -> ParsedLyrics
}
