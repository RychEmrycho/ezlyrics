import XCTest
@testable import ezlyrics

@MainActor
final class SyncEngineTests: XCTestCase {
    @MainActor
    func testUnsyncedLyrics() {
        let sut = SyncEngine()
        let parsed = ParsedLyrics(trackName: "Test", artistName: "Artist", isSynced: false, lines: [LyricLine(timestamp: 0, text: "Line", syllables: nil)])
        sut.currentLyrics = parsed
        
        let track = NowPlayingTrack(artist: "Artist", title: "Test", duration: 100, elapsedTime: 10, isPlaying: true, lastUpdatedTime: Date().timeIntervalSinceReferenceDate)
        sut.currentTrack = track
        
        XCTAssertEqual(sut.activeLine?.text, "Lyrics are not synced")
        XCTAssertNil(sut.nextLine)
    }
    
    @MainActor
    func testSyncedLyricsProgression() {
        let sut = SyncEngine()
        let lines = [
            LyricLine(timestamp: 10.0, text: "Line 1", syllables: nil),
            LyricLine(timestamp: 15.0, text: "Line 2", syllables: nil),
            LyricLine(timestamp: 20.0, text: "Line 3", syllables: nil)
        ]
        let parsed = ParsedLyrics(trackName: "Test", artistName: "Artist", isSynced: true, lines: lines)
        sut.currentLyrics = parsed
        
        // At 5 seconds (before first line)
        var track = NowPlayingTrack(artist: "Artist", title: "Test", duration: 100, elapsedTime: 5, isPlaying: false, lastUpdatedTime: Date().timeIntervalSinceReferenceDate)
        sut.currentTrack = track
        
        XCTAssertNil(sut.activeLine)
        XCTAssertEqual(sut.nextLine?.text, "Line 1")
        
        // At 12 seconds (during first line)
        track = NowPlayingTrack(artist: "Artist", title: "Test", duration: 100, elapsedTime: 12, isPlaying: false, lastUpdatedTime: Date().timeIntervalSinceReferenceDate)
        sut.currentTrack = track
        
        XCTAssertEqual(sut.activeLine?.text, "Line 1")
        XCTAssertEqual(sut.nextLine?.text, "Line 2")
    }
    
    @MainActor
    func testSmartSilenceDetection() {
        let sut = SyncEngine()
        let lines = [
            LyricLine(timestamp: 10.0, text: "Line 1", syllables: nil),
            LyricLine(timestamp: 30.0, text: "Line 2", syllables: nil)
        ]
        let parsed = ParsedLyrics(trackName: "Test", artistName: "Artist", isSynced: true, lines: lines)
        sut.currentLyrics = parsed
        
        // At 12 seconds (still active Line 1)
        var track = NowPlayingTrack(artist: "Artist", title: "Test", duration: 100, elapsedTime: 12, isPlaying: false, lastUpdatedTime: Date().timeIntervalSinceReferenceDate)
        sut.currentTrack = track
        
        XCTAssertEqual(sut.activeLine?.text, "Line 1")
        
        // At 20 seconds (time elapsed > 5s and time to next > 2s)
        track = NowPlayingTrack(artist: "Artist", title: "Test", duration: 100, elapsedTime: 20, isPlaying: false, lastUpdatedTime: Date().timeIntervalSinceReferenceDate)
        sut.currentTrack = track
        
        XCTAssertEqual(sut.activeLine?.text, "•••")
    }
}
