import Testing
@testable import ezlyrics

@Suite struct LyricsParserTests {
    @Test func ParsePlainLyrics() {
        let plain = "Line 1\nLine 2"
        let result = LyricsParser.parse(plain: plain, synced: nil, trackName: "Test", artistName: "Artist")
        
        #expect(!(result.isSynced))
        #expect(result.lines.count == 2)
        #expect(result.lines[0].text == "Line 1")
        #expect(result.lines[1].text == "Line 2")
    }

    @Test func ParseSyncedLyrics() {
        let synced = "[00:12.34]Line 1\n[00:15.67]Line 2"
        let result = LyricsParser.parse(plain: nil, synced: synced, trackName: "Test", artistName: "Artist")
        
        #expect(result.isSynced)
        #expect(result.lines.count == 2)
        
        // 12.34 seconds
        #expect(abs(result.lines[0].timestamp - 12.34) <= 0.01)
        #expect(result.lines[0].text == "Line 1")
        
        // 15.67 seconds
        #expect(abs(result.lines[1].timestamp - 15.67) <= 0.01)
        #expect(result.lines[1].text == "Line 2")
    }
    
    @Test func ParseSyncedLyricsWithSyllables() {
        let synced = "[00:10.00] <00:10.00>word1 <00:10.50>word2"
        let result = LyricsParser.parse(plain: nil, synced: synced, trackName: "Test", artistName: "Artist")
        
        #expect(result.isSynced)
        #expect(result.lines.count == 1)
        
        let line = result.lines[0]
        #expect(line.text == "word1 word2")
        
        #expect(line.syllables != nil)
        #expect(line.syllables?.count == 2)
        #expect(line.syllables?[0].text == "word1 ")
        #expect(abs((line.syllables?[0].timestamp ?? 0) - 10.00) <= 0.01)
        #expect(line.syllables?[1].text == "word2")
        #expect(abs((line.syllables?[1].timestamp ?? 0) - 10.50) <= 0.01)
    }
}
