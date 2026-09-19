import Testing
@testable import ezlyrics

@Suite struct TrackMetadataParserTests {
    
    @Test func NormalParsing() {
        let (artist, title) = TrackMetadataParser.parse(rawArtist: "Queen", rawTitle: "Bohemian Rhapsody")
        #expect(artist == "Queen")
        #expect(title == "Bohemian Rhapsody")
    }
    
    @Test func JunkRemoval() {
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
            #expect(title == expected, "Failed to clean: \(raw)")
        }
    }
    
    @Test func JapaneseYouTubeFormat() {
        let rawTitle = "KANA-BOON 『ないものねだり』Music Video"
        let (artist, title) = TrackMetadataParser.parse(rawArtist: "KANA-BOONVEVO", rawTitle: rawTitle)
        
        #expect(artist == "KANA-BOON")
        #expect(title == "ないものねだり")
    }
    
    @Test func JapaneseYouTubeFormatWithNoArtist() {
        let rawTitle = "『ないものねだり』"
        let (artist, title) = TrackMetadataParser.parse(rawArtist: "Channel Name", rawTitle: rawTitle)
        
        #expect(artist == "Channel Name")
        #expect(title == "ないものねだり")
    }
}
