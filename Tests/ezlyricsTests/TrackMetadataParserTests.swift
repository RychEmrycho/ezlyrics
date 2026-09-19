import XCTest
@testable import ezlyrics

final class TrackMetadataParserTests: XCTestCase {
    
    func testNormalParsing() {
        let (artist, title) = TrackMetadataParser.parse(rawArtist: "Queen", rawTitle: "Bohemian Rhapsody")
        XCTAssertEqual(artist, "Queen")
        XCTAssertEqual(title, "Bohemian Rhapsody")
    }
    
    func testJunkRemoval() {
        let cases = [
            ("Song Title (Official Music Video)", "Song Title"),
            ("Song Title [Lyrics]", "Song Title"),
            ("Song Title (Lyric Video)", "Song Title"),
            ("Song Title [Official Audio]", "Song Title"),
            ("Song Title (Visualizer)", "Song Title"),
            ("Song Title (official video)", "Song Title")
        ]
        
        for (raw, expected) in cases {
            let (_, title) = TrackMetadataParser.parse(rawArtist: "Artist", rawTitle: raw)
            XCTAssertEqual(title, expected, "Failed to clean: \(raw)")
        }
    }
    
    func testJapaneseYouTubeFormat() {
        let rawTitle = "KANA-BOON 『ないものねだり』Music Video"
        let (artist, title) = TrackMetadataParser.parse(rawArtist: "KANA-BOONVEVO", rawTitle: rawTitle)
        
        XCTAssertEqual(artist, "KANA-BOON")
        XCTAssertEqual(title, "ないものねだり")
    }
    
    func testJapaneseYouTubeFormatWithNoArtist() {
        let rawTitle = "『ないものねだり』"
        let (artist, title) = TrackMetadataParser.parse(rawArtist: "Channel Name", rawTitle: rawTitle)
        
        XCTAssertEqual(artist, "Channel Name")
        XCTAssertEqual(title, "ないものねだり")
    }
}
