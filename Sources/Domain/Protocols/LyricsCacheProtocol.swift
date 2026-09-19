import Foundation

/// Abstracts lyrics caching with a two-tier (memory + disk) strategy.
protocol LyricsCacheProtocol: Sendable {
    func getCachedLyrics(artist: String, title: String) async -> ParsedLyrics?
    func cache(lyrics: ParsedLyrics, artist: String, title: String) async
}
