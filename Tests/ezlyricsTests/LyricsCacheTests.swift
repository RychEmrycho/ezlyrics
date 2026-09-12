import XCTest
@testable import ezlyrics

final class LyricsCacheTests: XCTestCase {
    var sut: LyricsCache!
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        // Create a unique temporary directory for this test
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        sut = LyricsCache(cacheDirectory: tempDirectory)
    }

    override func tearDown() {
        // Clean up the disk after the test finishes
        try? FileManager.default.removeItem(at: tempDirectory)
        sut = nil
        super.tearDown()
    }

    func testCacheHitAndMiss() {
        let artist = "TestArtist"
        let title = "TestTitle"
        
        let parsed = ParsedLyrics(trackName: title, artistName: artist, isSynced: true, lines: [])
        sut.cache(lyrics: parsed, artist: artist, title: title)
        
        // Assert hit
        let retrieved = sut.getCachedLyrics(artist: artist, title: title)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.artistName, artist)
        XCTAssertEqual(retrieved?.trackName, title)
        
        // Assert miss
        let missed = sut.getCachedLyrics(artist: "Unknown", title: "Unknown")
        XCTAssertNil(missed)
    }
}
