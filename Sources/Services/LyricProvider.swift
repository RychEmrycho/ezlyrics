import Foundation

struct LyricSearchResult: Identifiable, Equatable, Sendable, Codable {
    let id: String
    let trackName: String
    let artistName: String
    let duration: TimeInterval?
    let hasSyncedLyrics: Bool
    let hasPlainLyrics: Bool
    let providerName: String
}

protocol LyricProvider: Sendable {
    var name: String { get }
    
    func getLyrics(artist: String, title: String, duration: TimeInterval) async throws -> ParsedLyrics
    func searchLyrics(query: String) async throws -> [LyricSearchResult]
    func fetchLyrics(for searchResult: LyricSearchResult) async throws -> ParsedLyrics
}
