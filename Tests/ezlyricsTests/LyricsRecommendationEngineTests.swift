import XCTest
@testable import ezlyrics

final class LyricsRecommendationEngineTests: XCTestCase {
    
    func testFiltersOutResultsWithoutLyrics() {
        let results = [
            SearchResult(id: 1, trackName: "A", artistName: "A", albumName: nil, duration: 100, instrumental: false, plainLyrics: nil, syncedLyrics: nil),
            SearchResult(id: 2, trackName: "B", artistName: "B", albumName: nil, duration: 100, instrumental: false, plainLyrics: "Text", syncedLyrics: nil)
        ]
        
        let track = Track(artist: "B", title: "B", duration: 100, elapsedTime: 0, isPlaying: true, lastUpdatedTime: 0)
        let recommended = LyricsRecommendationEngine.findBestMatch(in: results, forDuration: track.duration, expectedTitle: track.title, expectedArtist: track.artist)
        
        XCTAssertEqual(recommended?.id, 2)
    }
    
    func testFiltersOutResultsWithLargeDurationMismatch() {
        let results = [
            SearchResult(id: 1, trackName: "A", artistName: "A", albumName: nil, duration: 200, instrumental: false, plainLyrics: "Text", syncedLyrics: nil),
            SearchResult(id: 2, trackName: "A", artistName: "A", albumName: nil, duration: 102, instrumental: false, plainLyrics: "Text", syncedLyrics: nil)
        ]
        
        let track = Track(artist: "A", title: "A", duration: 100, elapsedTime: 0, isPlaying: true, lastUpdatedTime: 0)
        let recommended = LyricsRecommendationEngine.findBestMatch(in: results, forDuration: track.duration, expectedTitle: track.title, expectedArtist: track.artist)
        
        // 200 is too far off from 100, so id 2 (duration 102) should win even though they match equally in text
        XCTAssertEqual(recommended?.id, 2)
    }
    
    func testPrioritizesSyncedLyrics() {
        let results = [
            SearchResult(id: 1, trackName: "A", artistName: "A", albumName: nil, duration: 100, instrumental: false, plainLyrics: "Text", syncedLyrics: nil),
            SearchResult(id: 2, trackName: "A", artistName: "A", albumName: nil, duration: 100, instrumental: false, plainLyrics: "Text", syncedLyrics: "[00:10.00]Text")
        ]
        
        let track = Track(artist: "A", title: "A", duration: 100, elapsedTime: 0, isPlaying: true, lastUpdatedTime: 0)
        let recommended = LyricsRecommendationEngine.findBestMatch(in: results, forDuration: track.duration, expectedTitle: track.title, expectedArtist: track.artist)
        
        XCTAssertEqual(recommended?.id, 2)
    }
    
    func testPrioritizesExactStringMatches() {
        let results = [
            SearchResult(id: 1, trackName: "Wrong Title", artistName: "A", albumName: nil, duration: 100, instrumental: false, plainLyrics: "Text", syncedLyrics: nil),
            SearchResult(id: 2, trackName: "Exact Title", artistName: "Exact Artist", albumName: nil, duration: 100, instrumental: false, plainLyrics: "Text", syncedLyrics: nil)
        ]
        
        let track = Track(artist: "Exact Artist", title: "Exact Title", duration: 100, elapsedTime: 0, isPlaying: true, lastUpdatedTime: 0)
        let recommended = LyricsRecommendationEngine.findBestMatch(in: results, forDuration: track.duration, expectedTitle: track.title, expectedArtist: track.artist)
        
        XCTAssertEqual(recommended?.id, 2)
    }
}
