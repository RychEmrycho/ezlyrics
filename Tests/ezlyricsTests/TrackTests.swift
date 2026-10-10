import Testing
@testable import ezlyrics

@Suite struct TrackTests {
    
    @Test func IsSameSong_SameArtistAndTitle() {
        let track1 = Track(artist: "Queen", title: "Bohemian Rhapsody", duration: 355, elapsedTime: 10, isPlaying: true, lastUpdatedTime: 100)
        let track2 = Track(artist: "Queen", title: "Bohemian Rhapsody", duration: 355, elapsedTime: 20, isPlaying: false, lastUpdatedTime: 200)
        
        #expect(track1.isSameSong(as: track2))
        #expect(track2.isSameSong(as: track1))
    }
    
    @Test func IsSameSong_DifferentArtistOrTitle() {
        let base = Track(artist: "Queen", title: "Bohemian Rhapsody", duration: 355, elapsedTime: 0, isPlaying: true, lastUpdatedTime: 0)
        let diffArtist = Track(artist: "Other", title: "Bohemian Rhapsody", duration: 355, elapsedTime: 0, isPlaying: true, lastUpdatedTime: 0)
        let diffTitle = Track(artist: "Queen", title: "Radio Ga Ga", duration: 355, elapsedTime: 0, isPlaying: true, lastUpdatedTime: 0)
        
        #expect(!base.isSameSong(as: diffArtist))
        #expect(!base.isSameSong(as: diffTitle))
    }
    
    @Test func IsSameSong_WithNil() {
        let track: Track? = Track(artist: "Queen", title: "Bohemian Rhapsody", duration: 355, elapsedTime: 0, isPlaying: true, lastUpdatedTime: 0)
        let nilTrack: Track? = nil
        
        #expect(!track.isSameSong(as: nil))
        #expect(!nilTrack.isSameSong(as: track))
        #expect(nilTrack.isSameSong(as: nil))
    }
}
