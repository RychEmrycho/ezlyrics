import Testing
import Foundation
@testable import ezlyrics

@Suite final class LyricsCacheTests {
    var sut: LyricsCache!
    var tempDirectory: URL!

    init() {
        // Create a unique temporary directory for this test
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        sut = LyricsCache(cacheDirectory: tempDirectory)
    }

    deinit {
        // Clean up the disk after the test finishes
        try? FileManager.default.removeItem(at: tempDirectory)
        sut = nil
    }

    @Test func CacheHitAndMiss() async {
        let artist = "TestArtist"
        let title = "TestTitle"
        
        let parsed = ParsedLyrics(trackName: title, artistName: artist, isSynced: true, lines: [])
        await sut.cache(lyrics: parsed, artist: artist, title: title)
        
        // Assert hit
        let retrieved = await sut.getCachedLyrics(artist: artist, title: title)
        #expect(retrieved != nil)
        // Assert hit
        #expect(retrieved?.artistName == artist)
        #expect(retrieved?.trackName == title)
        
        // Assert miss
        let missed = await sut.getCachedLyrics(artist: "Unknown", title: "Unknown")
        #expect(missed == nil)
    }
}
