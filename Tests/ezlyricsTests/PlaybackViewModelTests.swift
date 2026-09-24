import Testing
import Foundation
@testable import ezlyrics

@MainActor
@Suite struct PlaybackViewModelTests {
    
    final class MockRepository: LyricsRepository, @unchecked Sendable {
        var fetchResultToReturn: FetchResult?
        var fetchCount = 0
        var overrideCalled = false
        
        func fetchBestLyrics(for track: Track) async -> FetchResult {
            fetchCount += 1
            return fetchResultToReturn ?? FetchResult(lyrics: ParsedLyrics(trackName: "", artistName: "", isSynced: false, lines: [], detectedLanguage: nil), recommendedResult: nil, searchQuery: "")
        }
        
        func searchLyrics(query: String) async throws -> [SearchResult] {
            return []
        }
        
        func applyOverride(_ result: SearchResult, for track: Track) async -> ParsedLyrics {
            overrideCalled = true
            return ParsedLyrics(trackName: "", artistName: "", isSynced: false, lines: [], detectedLanguage: nil)
        }
    }
    
    var repo: MockRepository!
    var sut: PlaybackViewModel!
    
    init() async throws {
        repo = MockRepository()
        sut = PlaybackViewModel(repository: repo)
    }
    
    @Test func OnTrackChanged_ValidTrack_TriggersFetch() async {
        let track = Track(artist: "Artist", title: "Title", duration: 100, elapsedTime: 0, isPlaying: true, lastUpdatedTime: Date().timeIntervalSinceReferenceDate)
        
        let expectedResult = FetchResult(lyrics: ParsedLyrics(trackName: "Title", artistName: "Artist", isSynced: true, lines: [], detectedLanguage: nil), recommendedResult: nil, searchQuery: "")
        repo.fetchResultToReturn = expectedResult
        
        await withCheckedContinuation { continuation in
            sut.onLyricsFetched = { result in
                #expect(result.lyrics.artistName == "Artist")
                continuation.resume()
            }
            
            sut.onTrackChanged(track)
        }
        
        #expect(repo.fetchCount == 1)
        #expect(sut.currentLyrics?.artistName == "Artist")
    }
    
    @Test func OnTrackChanged_NilTrack_ClearsLyrics() {
        sut.currentLyrics = ParsedLyrics(trackName: "Title", artistName: "Artist", isSynced: true, lines: [], detectedLanguage: nil)
        
        sut.onTrackChanged(nil)
        
        #expect(sut.currentLyrics == nil)
        #expect(repo.fetchCount == 0)
    }
    
    @Test func CurrentPlaybackTime_IsPlaying() {
        // Track was updated 10 seconds ago at 0 elapsed time, and it is playing.
        // So expected time is 10.
        let now = Date()
        let past = now.addingTimeInterval(-10)
        let track = Track(artist: "Artist", title: "Title", duration: 100, elapsedTime: 0, isPlaying: true, lastUpdatedTime: past.timeIntervalSinceReferenceDate)
        
        sut.currentTrack = track
        
        let time = sut.currentPlaybackTime(currentDate: now)
        #expect(abs(time - 10.0) <= 0.1)
    }
    
    @Test func CurrentPlaybackTime_Paused() {
        // Track was updated 10 seconds ago at 5 elapsed time, but it is paused.
        // So expected time is still 5.
        let now = Date()
        let past = now.addingTimeInterval(-10)
        let track = Track(artist: "Artist", title: "Title", duration: 100, elapsedTime: 5, isPlaying: false, lastUpdatedTime: past.timeIntervalSinceReferenceDate)
        
        sut.currentTrack = track
        
        let time = sut.currentPlaybackTime(currentDate: now)
        #expect(time == 5.0)
    }
    
    @Test func CurrentPlaybackTime_WithOffset() {
        let track = Track(artist: "Artist", title: "Title", duration: 100, elapsedTime: 5, isPlaying: false, lastUpdatedTime: Date().timeIntervalSinceReferenceDate)
        sut.currentTrack = track
        sut.userOffset = 2.0
        sut.jumpOffset = 1.5
        
        let time = sut.currentPlaybackTime()
        #expect(time == 8.5)
    }
    
    @Test func OffsetsResetOnNewTrack() {
        let track1 = Track(artist: "Artist 1", title: "Title", duration: 100, elapsedTime: 5, isPlaying: false, lastUpdatedTime: 0)
        sut.currentTrack = track1
        sut.userOffset = 2.0
        sut.jumpOffset = 5.0
        
        let track2 = Track(artist: "Artist 2", title: "Title", duration: 100, elapsedTime: 5, isPlaying: false, lastUpdatedTime: 0)
        sut.currentTrack = track2
        
        #expect(sut.userOffset == 0.0)
        #expect(sut.jumpOffset == 0.0)
    }
    
    @Test func JumpOffsetResetsOnScrub() {
        let track1 = Track(artist: "Artist 1", title: "Title", duration: 100, elapsedTime: 5, isPlaying: false, lastUpdatedTime: 0)
        sut.currentTrack = track1
        sut.userOffset = 2.0
        sut.jumpOffset = 5.0
        
        // Scrub 5 seconds forward
        let track2 = Track(artist: "Artist 1", title: "Title", duration: 100, elapsedTime: 10, isPlaying: false, lastUpdatedTime: 1)
        sut.currentTrack = track2
        
        #expect(sut.userOffset == 2.0) // User offset should remain
        #expect(sut.jumpOffset == 0.0) // Jump offset should reset
    }
}
