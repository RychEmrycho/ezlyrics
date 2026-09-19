import Foundation

struct Track: Equatable {
    var artist: String
    var title: String
    var duration: TimeInterval
    var elapsedTime: TimeInterval
    var isPlaying: Bool
    var lastUpdatedTime: TimeInterval
}
