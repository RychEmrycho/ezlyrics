import XCTest
@testable import ezlyrics

final class LRCParserTests: XCTestCase {
    func testParsePlainLyrics() {
        let plain = "Line 1\nLine 2"
        let result = LRCParser.parse(plain: plain, synced: nil, trackName: "Test", artistName: "Artist")
        
        XCTAssertFalse(result.isSynced)
        XCTAssertEqual(result.lines.count, 2)
        XCTAssertEqual(result.lines[0].text, "Line 1")
        XCTAssertEqual(result.lines[1].text, "Line 2")
    }

    func testParseSyncedLyrics() {
        let synced = "[00:12.34]Line 1\n[00:15.67]Line 2"
        let result = LRCParser.parse(plain: nil, synced: synced, trackName: "Test", artistName: "Artist")
        
        XCTAssertTrue(result.isSynced)
        XCTAssertEqual(result.lines.count, 2)
        
        // 12.34 seconds
        XCTAssertEqual(result.lines[0].timestamp, 12.34, accuracy: 0.01)
        XCTAssertEqual(result.lines[0].text, "Line 1")
        
        // 15.67 seconds
        XCTAssertEqual(result.lines[1].timestamp, 15.67, accuracy: 0.01)
        XCTAssertEqual(result.lines[1].text, "Line 2")
    }
    
    func testParseSyncedLyricsWithSyllables() {
        let synced = "[00:10.00] <00:10.00>word1 <00:10.50>word2"
        let result = LRCParser.parse(plain: nil, synced: synced, trackName: "Test", artistName: "Artist")
        
        XCTAssertTrue(result.isSynced)
        XCTAssertEqual(result.lines.count, 1)
        
        let line = result.lines[0]
        XCTAssertEqual(line.text, "word1 word2")
        
        XCTAssertNotNil(line.syllables)
        XCTAssertEqual(line.syllables?.count, 2)
        XCTAssertEqual(line.syllables?[0].text, "word1 ")
        XCTAssertEqual(line.syllables?[0].timestamp ?? 0, 10.00, accuracy: 0.01)
        XCTAssertEqual(line.syllables?[1].text, "word2")
        XCTAssertEqual(line.syllables?[1].timestamp ?? 0, 10.50, accuracy: 0.01)
    }
}
