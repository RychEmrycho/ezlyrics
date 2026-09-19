import Testing
import Foundation
@testable import ezlyrics

@MainActor
@Suite struct PlaybackViewModelSyncTests {
    
    private func makePlaybackVM() -> PlaybackViewModel {
        let client = LRCLIBClient()
        let cache = LyricsCache()
        let repo = LyricsRepositoryImpl(client: client, cache: cache)
        return PlaybackViewModel(repository: repo)
    }
    
    @MainActor
    @Test func UnsyncedLyrics() {
        let sut = makePlaybackVM()
        let parsed = ParsedLyrics(trackName: "Test", artistName: "Artist", isSynced: false, lines: [LyricLine(timestamp: 0, text: "Line", syllables: nil)])
        sut.currentLyrics = parsed
        
        let track = Track(artist: "Artist", title: "Test", duration: 100, elapsedTime: 10, isPlaying: true, lastUpdatedTime: Date().timeIntervalSinceReferenceDate)
        sut.currentTrack = track
        
        #expect(sut.activeLine?.text == "Lyrics are not synced")
        #expect(sut.nextLine == nil)
    }
    
    @MainActor
    @Test func SyncedLyricsProgression() {
        let sut = makePlaybackVM()
        let lines = [
            LyricLine(timestamp: 10.0, text: "Line 1", syllables: nil),
            LyricLine(timestamp: 15.0, text: "Line 2", syllables: nil),
            LyricLine(timestamp: 20.0, text: "Line 3", syllables: nil)
        ]
        let parsed = ParsedLyrics(trackName: "Test", artistName: "Artist", isSynced: true, lines: lines)
        sut.currentLyrics = parsed
        
        // At 5 seconds (before first line)
        var track = Track(artist: "Artist", title: "Test", duration: 100, elapsedTime: 5, isPlaying: false, lastUpdatedTime: Date().timeIntervalSinceReferenceDate)
        sut.currentTrack = track
        
        #expect(sut.activeLine == nil)
        #expect(sut.nextLine?.text == "Line 1")
        
        // At 12 seconds (during first line)
        track = Track(artist: "Artist", title: "Test", duration: 100, elapsedTime: 12, isPlaying: false, lastUpdatedTime: Date().timeIntervalSinceReferenceDate)
        sut.currentTrack = track
        
        #expect(sut.activeLine?.text == "Line 1")
        #expect(sut.nextLine?.text == "Line 2")
    }
    
    @MainActor
    @Test func SmartSilenceDetection() {
        let sut = makePlaybackVM()
        let lines = [
            LyricLine(timestamp: 10.0, text: "Line 1", syllables: nil),
            LyricLine(timestamp: 30.0, text: "Line 2", syllables: nil)
        ]
        let parsed = ParsedLyrics(trackName: "Test", artistName: "Artist", isSynced: true, lines: lines)
        sut.currentLyrics = parsed
        
        // At 12 seconds (still active Line 1)
        var track = Track(artist: "Artist", title: "Test", duration: 100, elapsedTime: 12, isPlaying: false, lastUpdatedTime: Date().timeIntervalSinceReferenceDate)
        sut.currentTrack = track
        
        #expect(sut.activeLine?.text == "Line 1")
        
        // At 20 seconds (time elapsed > 5s and time to next > 2s)
        track = Track(artist: "Artist", title: "Test", duration: 100, elapsedTime: 20, isPlaying: false, lastUpdatedTime: Date().timeIntervalSinceReferenceDate)
        sut.currentTrack = track
        
        #expect(sut.activeLine?.text == "•••")
    }
}
