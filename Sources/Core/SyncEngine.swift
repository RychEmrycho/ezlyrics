import Foundation
import Combine

@MainActor
class SyncEngine: ObservableObject {
    @Published var activeLine: LyricLine?
    @Published var nextLine: LyricLine?
    @Published var nextNextLine: LyricLine?
    
    // User offset in seconds
    @Published var userOffset: TimeInterval = 0
    
    var currentLyrics: ParsedLyrics? {
        didSet {
            recalculateLines()
        }
    }
    
    var currentTrack: NowPlayingTrack? {
        didSet {
            if oldValue?.title != currentTrack?.title || oldValue?.artist != currentTrack?.artist {
                userOffset = 0
            }
            if currentTrack?.isPlaying == true {
                startTimer()
            } else {
                stopTimer()
            }
            recalculateLines()
        }
    }
    
    private var displayLinkTimer: Timer?
    
    func startTimer() {
        if displayLinkTimer == nil {
            displayLinkTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.recalculateLines()
                }
            }
            RunLoop.main.add(displayLinkTimer!, forMode: .common)
        }
    }
    
    func stopTimer() {
        displayLinkTimer?.invalidate()
        displayLinkTimer = nil
    }
    
    func currentEffectiveTime() -> TimeInterval {
        guard let track = currentTrack else { return userOffset }
        var currentElapsed = track.elapsedTime
        if track.isPlaying {
            let timeSinceLastUpdate = Date().timeIntervalSinceReferenceDate - track.lastUpdatedTime
            currentElapsed += timeSinceLastUpdate
        }
        return currentElapsed + userOffset
    }
    
    private func recalculateLines() {
        guard let lyrics = currentLyrics, !lyrics.lines.isEmpty, currentTrack != nil else {
            activeLine = nil
            nextLine = nil
            return
        }
        
        guard lyrics.isSynced else {
            if activeLine?.text != "Lyrics are not synced" {
                activeLine = LyricLine(timestamp: 0, text: "Lyrics are not synced", syllables: nil)
                nextLine = nil
            }
            return
        }
        
        // Calculate effective time
        let effectiveTime = currentEffectiveTime()
        
        // Binary search for the active line
        let lines = lyrics.lines
        var low = 0
        var high = lines.count - 1
        var activeIndex = -1
        
        while low <= high {
            let mid = (low + high) / 2
            if lines[mid].timestamp <= effectiveTime {
                activeIndex = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        
        if activeIndex >= 0 {
            let newActive = lines[activeIndex]
            var nextL: LyricLine?
            var nextNextL: LyricLine?
            
            if activeIndex + 1 < lines.count {
                nextL = lines[activeIndex + 1]
            }
            if activeIndex + 2 < lines.count {
                nextNextL = lines[activeIndex + 2]
            }
            
            // Smart Silence detection
            if let nextLineItem = nextL {
                let timeSinceActive = effectiveTime - newActive.timestamp
                let timeUntilNext = nextLineItem.timestamp - effectiveTime
                
                if timeSinceActive > 5.0 && timeUntilNext > 2.0 {
                    let gapLine = LyricLine(id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, timestamp: newActive.timestamp + 5.0, text: "•••", syllables: nil)
                    if activeLine != gapLine {
                        activeLine = gapLine
                    }
                } else {
                    if activeLine != newActive {
                        activeLine = newActive
                    }
                }
            } else {
                let timeSinceActive = effectiveTime - newActive.timestamp
                if timeSinceActive > 8.0 {
                    let endLine = LyricLine(id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, timestamp: newActive.timestamp + 8.0, text: "♫", syllables: nil)
                    if activeLine != endLine {
                        activeLine = endLine
                    }
                } else {
                    if activeLine != newActive {
                        activeLine = newActive
                    }
                }
            }
            
            if nextLine != nextL {
                nextLine = nextL
            }
            
            if nextNextLine != nextNextL {
                nextNextLine = nextNextL
            }
        } else {
            activeLine = nil
            if !lines.isEmpty {
                nextLine = lines[0]
                if lines.count > 1 {
                    nextNextLine = lines[1]
                } else {
                    nextNextLine = nil
                }
            } else {
                nextLine = nil
                nextNextLine = nil
            }
        }
    }
}
