import Foundation

struct Track: Equatable {
    var artist: String
    var title: String
    var duration: TimeInterval
    var elapsedTime: TimeInterval
    var isPlaying: Bool
    var lastUpdatedTime: TimeInterval
    
    func isSameSong(as other: Track?) -> Bool {
        guard let other = other else { return false }
        return artist == other.artist && title == other.title
    }
}

extension Optional where Wrapped == Track {
    func isSameSong(as other: Track?) -> Bool {
        switch (self, other) {
        case (.none, .none):
            return true
        case (.some(let a), .some(let b)):
            return a.isSameSong(as: b)
        default:
            return false
        }
    }
}
