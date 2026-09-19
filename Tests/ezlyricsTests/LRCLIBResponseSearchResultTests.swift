import Testing
@testable import ezlyrics

@Suite struct LRCLIBResponseSearchResultTests {
    
    @Test func MapToSearchResult() {
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
        
        #expect(result.id == 123)
        #expect(result.trackName == "Test Track")
        #expect(result.artistName == "Test Artist")
        #expect(result.albumName == "Test Album")
        #expect(result.duration == 210.5)
        #expect(result.instrumental == false)
        #expect(result.plainLyrics == "Plain Text")
        #expect(result.syncedLyrics == "[00:10.00]Synced Text")
    }
}
