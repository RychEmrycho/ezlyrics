import Foundation

struct ActiveLyricState: Equatable {
    let activeLine: LyricLine?
    let nextLine: LyricLine?
    let nextNextLine: LyricLine?
    let activeIndex: Int
}

struct LyricResolver {
    let silenceGapThreshold: TimeInterval
    let endSilenceThreshold: TimeInterval
    
    init(silenceGapThreshold: TimeInterval = 5.0, endSilenceThreshold: TimeInterval = 8.0) {
        self.silenceGapThreshold = silenceGapThreshold
        self.endSilenceThreshold = endSilenceThreshold
    }
    
    func resolve(effectiveTime: TimeInterval, lines: [LyricLine], currentIndex: Int) -> ActiveLyricState {
        guard !lines.isEmpty else {
            return ActiveLyricState(activeLine: nil, nextLine: nil, nextNextLine: nil, activeIndex: -1)
        }
        
        let activeIndex = findActiveLineIndex(effectiveTime: effectiveTime, lines: lines, currentIndex: currentIndex)
        
        if activeIndex >= 0 {
            return calculateActiveLines(activeIndex: activeIndex, effectiveTime: effectiveTime, lines: lines)
        } else {
            return ActiveLyricState(
                activeLine: nil,
                nextLine: lines.isEmpty ? nil : lines[0],
                nextNextLine: lines.count > 1 ? lines[1] : nil,
                activeIndex: -1
            )
        }
    }
    
    private func findActiveLineIndex(effectiveTime: TimeInterval, lines: [LyricLine], currentIndex: Int) -> Int {
        // Optimize: check if we're still on the same line
        if currentIndex >= 0 && currentIndex < lines.count {
            let line = lines[currentIndex]
            let nextTimestamp = (currentIndex + 1 < lines.count) ? lines[currentIndex + 1].timestamp : Double.greatestFiniteMagnitude
            if effectiveTime >= line.timestamp && effectiveTime < nextTimestamp {
                return currentIndex
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
    
    private func calculateActiveLines(activeIndex: Int, effectiveTime: TimeInterval, lines: [LyricLine]) -> ActiveLyricState {
        let newActive = lines[activeIndex]
        let nextL = activeIndex + 1 < lines.count ? lines[activeIndex + 1] : nil
        let nextNextL = activeIndex + 2 < lines.count ? lines[activeIndex + 2] : nil
        
        var calculatedActiveLine: LyricLine = newActive
        
        // Smart Silence detection
        if let nextLineItem = nextL {
            let timeSinceActive = effectiveTime - newActive.timestamp
            let timeUntilNext = nextLineItem.timestamp - effectiveTime
            
            if timeSinceActive > silenceGapThreshold && timeUntilNext > 2.0 {
                calculatedActiveLine = LyricLine(id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, timestamp: newActive.timestamp + silenceGapThreshold, text: "•••", syllables: nil)
            }
        } else {
            let timeSinceActive = effectiveTime - newActive.timestamp
            if timeSinceActive > endSilenceThreshold {
                calculatedActiveLine = LyricLine(id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, timestamp: newActive.timestamp + endSilenceThreshold, text: "♫", syllables: nil)
            }
        }
        
        return ActiveLyricState(
            activeLine: calculatedActiveLine,
            nextLine: nextL,
            nextNextLine: nextNextL,
            activeIndex: activeIndex
        )
    }
}
