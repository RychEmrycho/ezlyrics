import Foundation

struct LRCLIBResponse: Codable, Equatable {
    let id: Int
    let trackName: String
    let artistName: String
    let albumName: String?
    let duration: Double?
    let instrumental: Bool
    let plainLyrics: String?
    let syncedLyrics: String?
}
