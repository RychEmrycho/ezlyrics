import Foundation
import Combine

@MainActor
class PlaybackViewModel: ObservableObject {
    @Published var activeLine: LyricLine?
    @Published var nextLine: LyricLine?
    @Published var nextNextLine: LyricLine?
    
    @Published var userOffset: TimeInterval = 0
    
    private var currentLineIndex: Int = -1
    
    private let resolver: LyricResolver
    private let repository: LyricsRepository
    
    init(resolver: LyricResolver = LyricResolver(), repository: LyricsRepository) {
        self.resolver = resolver
        self.repository = repository
    }
    
    // Playback Controls
    var togglePlayPause: (() -> Void)?
    var nextTrack: (() -> Void)?
    var previousTrack: (() -> Void)?
    
    @Published var currentLyrics: ParsedLyrics? {
        didSet {
            recalculateLines()
        }
    }
    
    var currentTrack: Track? {
        didSet {
            if oldValue?.title != currentTrack?.title || oldValue?.artist != currentTrack?.artist {
                userOffset = 0
            }
            if currentTrack?.isPlaying == true {
                startSyncing()
            } else {
                stopSyncing()
            }
            recalculateLines()
        }
    }
    
    private var syncTimer: Timer?
    
    func startSyncing() {
        if syncTimer == nil {
            syncTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.recalculateLines()
                }
            }
            RunLoop.main.add(syncTimer!, forMode: .common)
        }
    }
    
    func stopSyncing() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    func currentPlaybackTime(currentDate: Date = Date()) -> TimeInterval {
        guard let track = currentTrack else { return userOffset }
        var currentElapsed = track.elapsedTime
        if track.isPlaying {
            let timeSinceLastUpdate = currentDate.timeIntervalSinceReferenceDate - track.lastUpdatedTime
            currentElapsed += timeSinceLastUpdate
        }
        return currentElapsed + userOffset
    }
    
    /// Called by the coordinator when a new track is detected.
    func onTrackChanged(_ track: Track?) {
        currentTrack = track
        if let track = track {
            fetchLyrics(for: track)
        } else {
            currentLyrics = nil
        }
    }
    
    private func fetchLyrics(for track: Track) {
        Task { [weak self] in
            guard let self = self else { return }
            let result = await self.repository.fetchBestLyrics(for: track)
            self.currentLyrics = result.lyrics
            self.onLyricsFetched?(result)
        }
    }
    
    /// Callback for the coordinator to forward fetch results to other ViewModels.
    var onLyricsFetched: ((FetchResult) -> Void)?
    
    private func recalculateLines() {
        guard let lyrics = currentLyrics, !lyrics.lines.isEmpty, currentTrack != nil else {
            activeLine = nil
            nextLine = nil
            nextNextLine = nil
            currentLineIndex = -1
            return
        }
        
        guard lyrics.isSynced else {
            if activeLine?.text != "Lyrics are not synced" {
                activeLine = LyricLine(timestamp: 0, text: "Lyrics are not synced", syllables: nil)
                nextLine = nil
                nextNextLine = nil
                currentLineIndex = -1
            }
            return
        }
        
        let effectiveTime = currentPlaybackTime()
        
        let resolution = resolver.resolve(
            effectiveTime: effectiveTime,
            lines: lyrics.lines,
            currentIndex: currentLineIndex
        )
        
        if activeLine != resolution.activeLine {
            activeLine = resolution.activeLine
        }
        if nextLine != resolution.nextLine {
            nextLine = resolution.nextLine
        }
        if nextNextLine != resolution.nextNextLine {
            nextNextLine = resolution.nextNextLine
        }
        
        currentLineIndex = resolution.activeIndex
    }
}
