import Foundation

/// Provider-agnostic representation of a lyrics search result.
/// The Data layer maps provider-specific DTOs (e.g. LRCLIBResponse) into this type.
struct SearchResult: Equatable, Identifiable {
    let id: Int
    let trackName: String
    let artistName: String
    let albumName: String?
    let duration: Double?
    let instrumental: Bool
    let plainLyrics: String?
    let syncedLyrics: String?
}
