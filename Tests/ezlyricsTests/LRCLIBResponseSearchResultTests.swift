import XCTest
@testable import ezlyrics

final class LRCLIBResponseSearchResultTests: XCTestCase {
    
    func testMapToSearchResult() {
        let response = LRCLIBResponse(
            id: 123,
            trackName: "Test Track",
            artistName: "Test Artist",
            albumName: "Test Album",
            duration: 210.5,
            instrumental: false,
            plainLyrics: "Plain Text",
            syncedLyrics: "[00:10.00]Synced Text"
        )
        
        let result = response.toSearchResult()
        
        XCTAssertEqual(result.id, 123)
        XCTAssertEqual(result.trackName, "Test Track")
        XCTAssertEqual(result.artistName, "Test Artist")
        XCTAssertEqual(result.albumName, "Test Album")
        XCTAssertEqual(result.duration, 210.5)
        XCTAssertEqual(result.instrumental, false)
        XCTAssertEqual(result.plainLyrics, "Plain Text")
        XCTAssertEqual(result.syncedLyrics, "[00:10.00]Synced Text")
    }
}
