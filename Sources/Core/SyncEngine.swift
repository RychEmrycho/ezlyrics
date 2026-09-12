import Foundation
import Combine

@MainActor
class SyncEngine: ObservableObject {
    @Published var activeLine: LyricLine?
    @Published var nextLine: LyricLine?
    @Published var nextNextLine: LyricLine?
    
    // User offset in seconds
    @Published var userOffset: TimeInterval = 0
    
    private var currentLineIndex: Int = -1
    
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
        let lines = lyrics.lines
        
        let activeIndex = findActiveLineIndex(effectiveTime: effectiveTime, lines: lines)
        
        if activeIndex >= 0 {
            updateActiveLines(activeIndex: activeIndex, effectiveTime: effectiveTime, lines: lines)
        } else {
            currentLineIndex = -1
            activeLine = nil
            if !lines.isEmpty {
                nextLine = lines[0]
                nextNextLine = lines.count > 1 ? lines[1] : nil
            } else {
                nextLine = nil
                nextNextLine = nil
            }
        }
    }
    
    private func findActiveLineIndex(effectiveTime: TimeInterval, lines: [LyricLine]) -> Int {
        // Optimize: check if we're still on the same line
        if currentLineIndex >= 0 && currentLineIndex < lines.count {
            let line = lines[currentLineIndex]
            let nextTimestamp = (currentLineIndex + 1 < lines.count) ? lines[currentLineIndex + 1].timestamp : Double.greatestFiniteMagnitude
            if effectiveTime >= line.timestamp && effectiveTime < nextTimestamp {
                return currentLineIndex
            }
        }
        
        // Binary search for the active line if we didn't find it via optimization
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
        return activeIndex
    }
    
    private func updateActiveLines(activeIndex: Int, effectiveTime: TimeInterval, lines: [LyricLine]) {
        let newActive = lines[activeIndex]
        let nextL = activeIndex + 1 < lines.count ? lines[activeIndex + 1] : nil
        let nextNextL = activeIndex + 2 < lines.count ? lines[activeIndex + 2] : nil
        
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
        
        currentLineIndex = activeIndex
    }
}
