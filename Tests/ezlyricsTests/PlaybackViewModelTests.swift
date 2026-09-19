import XCTest
@testable import ezlyrics

@MainActor
final class PlaybackViewModelTests: XCTestCase {
    
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
    
    override func setUp() async throws {
        repo = MockRepository()
        sut = PlaybackViewModel(repository: repo)
    }
    
    func testOnTrackChanged_ValidTrack_TriggersFetch() async {
        let expectation = XCTestExpectation(description: "Wait for onLyricsFetched")
        let track = Track(artist: "Artist", title: "Title", duration: 100, elapsedTime: 0, isPlaying: true, lastUpdatedTime: Date().timeIntervalSinceReferenceDate)
        
        let expectedResult = FetchResult(lyrics: ParsedLyrics(trackName: "Title", artistName: "Artist", isSynced: true, lines: [], detectedLanguage: nil), recommendedResult: nil, searchQuery: "")
        repo.fetchResultToReturn = expectedResult
        
        sut.onLyricsFetched = { result in
            XCTAssertEqual(result.lyrics.artistName, "Artist")
            expectation.fulfill()
        }
        
        sut.onTrackChanged(track)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(repo.fetchCount, 1)
        XCTAssertEqual(sut.currentLyrics?.artistName, "Artist")
    }
    
    func testOnTrackChanged_NilTrack_ClearsLyrics() {
        sut.currentLyrics = ParsedLyrics(trackName: "Title", artistName: "Artist", isSynced: true, lines: [], detectedLanguage: nil)
        
        sut.onTrackChanged(nil)
        
        XCTAssertNil(sut.currentLyrics)
        XCTAssertEqual(repo.fetchCount, 0)
    }
    
    func testCurrentPlaybackTime_IsPlaying() {
        // Track was updated 10 seconds ago at 0 elapsed time, and it is playing.
        // So expected time is 10.
        let now = Date()
        let past = now.addingTimeInterval(-10)
        let track = Track(artist: "Artist", title: "Title", duration: 100, elapsedTime: 0, isPlaying: true, lastUpdatedTime: past.timeIntervalSinceReferenceDate)
        
        sut.currentTrack = track
        
        let time = sut.currentPlaybackTime(currentDate: now)
        XCTAssertEqual(time, 10.0, accuracy: 0.1)
    }
    
    func testCurrentPlaybackTime_Paused() {
        // Track was updated 10 seconds ago at 5 elapsed time, but it is paused.
        // So expected time is still 5.
        let now = Date()
        let past = now.addingTimeInterval(-10)
        let track = Track(artist: "Artist", title: "Title", duration: 100, elapsedTime: 5, isPlaying: false, lastUpdatedTime: past.timeIntervalSinceReferenceDate)
        
        sut.currentTrack = track
        
        let time = sut.currentPlaybackTime(currentDate: now)
        XCTAssertEqual(time, 5.0)
    }
    
    func testCurrentPlaybackTime_WithOffset() {
        let track = Track(artist: "Artist", title: "Title", duration: 100, elapsedTime: 5, isPlaying: false, lastUpdatedTime: Date().timeIntervalSinceReferenceDate)
        sut.currentTrack = track
        sut.userOffset = 2.0
        
        let time = sut.currentPlaybackTime()
        XCTAssertEqual(time, 7.0)
    }
    
    func testUserOffsetResetsOnNewTrack() {
        let track1 = Track(artist: "Artist 1", title: "Title", duration: 100, elapsedTime: 5, isPlaying: false, lastUpdatedTime: 0)
        sut.currentTrack = track1
        sut.userOffset = 2.0
        
        let track2 = Track(artist: "Artist 2", title: "Title", duration: 100, elapsedTime: 5, isPlaying: false, lastUpdatedTime: 0)
        sut.currentTrack = track2
        
        XCTAssertEqual(sut.userOffset, 0.0) // Changed artist, should reset
    }
}
