import XCTest
@testable import ezlyrics

final class MockLyricsCache: LyricsCacheProtocol, @unchecked Sendable {
    var cachedLyrics: ParsedLyrics?
    var cachedArtist: String?
    var cachedTitle: String?
    var didCache = false
    var didClear = false
    
    func getCachedLyrics(artist: String, title: String) async -> ParsedLyrics? {
        if artist == cachedArtist && title == cachedTitle {
            return cachedLyrics
        }
        return nil
    }
    
    func cache(lyrics: ParsedLyrics, artist: String, title: String) async {
        cachedLyrics = lyrics
        cachedArtist = artist
        cachedTitle = title
        didCache = true
    }
    
    func clearCache() async {
        didClear = true
    }
}

final class LyricsRepoMockURLSession: URLSessionProtocol, @unchecked Sendable {
    var responses: [(Data?, URLResponse?, Error?)] = []
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard !responses.isEmpty else {
            fatalError("No mocked response available for request: \(request.url?.absoluteString ?? "unknown")")
        }
        let (mockData, mockResponse, mockError) = responses.removeFirst()
        if let error = mockError {
            throw error
        }
        return (mockData ?? Data(), mockResponse ?? URLResponse())
    }
}

@MainActor
final class LyricsRepositoryImplTests: XCTestCase {
    
    var session: LyricsRepoMockURLSession!
    var client: LRCLIBClient!
    var cache: MockLyricsCache!
    var repository: LyricsRepositoryImpl!
    
    override func setUp() async throws {
        session = LyricsRepoMockURLSession()
        client = LRCLIBClient(session: session)
        cache = MockLyricsCache()
        repository = LyricsRepositoryImpl(client: client, cache: cache)
    }
    
    func testFetchBestLyrics_CacheHit() async {
        let track = Track(artist: "Queen", title: "Bohemian Rhapsody", duration: 0, elapsedTime: 0, isPlaying: true, lastUpdatedTime: 0)
        let cachedLyrics = ParsedLyrics(trackName: "Bohemian Rhapsody", artistName: "Queen", isSynced: true, lines: [], detectedLanguage: nil)
        
        await cache.cache(lyrics: cachedLyrics, artist: "Queen", title: "Bohemian Rhapsody")
        
        let result = await repository.fetchBestLyrics(for: track)
        
        XCTAssertEqual(result.lyrics.artistName, "Queen")
        XCTAssertEqual(result.recommendedResult?.syncedLyrics, "cached")
    }
    
    func testFetchBestLyrics_ExactMatch() async throws {
        let track = Track(artist: "Queen", title: "Bohemian Rhapsody", duration: 355, elapsedTime: 0, isPlaying: true, lastUpdatedTime: 0)
        
        let json = """
        {
            "id": 1,
            "trackName": "Bohemian Rhapsody",
            "artistName": "Queen",
            "albumName": "A Night at the Opera",
            "duration": 355,
            "instrumental": false,
            "plainLyrics": "Is this the real life?",
            "syncedLyrics": "[00:00.00] Is this the real life?"
        }
        """
        
        session.responses = [(
            json.data(using: .utf8),
            HTTPURLResponse(url: URL(string: "https://lrclib.net")!, statusCode: 200, httpVersion: nil, headerFields: nil),
            nil
        )]
        
        let result = await repository.fetchBestLyrics(for: track)
        
        XCTAssertEqual(result.lyrics.artistName, "Queen")
        XCTAssertTrue(result.lyrics.isSynced)
        XCTAssertEqual(result.lyrics.lines.first?.text, "Is this the real life?")
        XCTAssertTrue(cache.didCache)
    }
    
    func testFetchBestLyrics_FallbackToSearch() async throws {
        let track = Track(artist: "Queen", title: "Bohemian Rhapsody", duration: 355, elapsedTime: 0, isPlaying: true, lastUpdatedTime: 0)
        
        // Mock getLyrics failing with 404
        // To do this, we need to inject responses sequentially or use the path. Let's inspect the request.
        
        // Actually, we can just replace the session's data method to check the URL
        let getResponse = HTTPURLResponse(url: URL(string: "https://lrclib.net/api/get")!, statusCode: 404, httpVersion: nil, headerFields: nil)!
        
        let searchJson = """
        [
            {
                "id": 1,
                "trackName": "Bohemian Rhapsody",
                "artistName": "Queen",
                "albumName": "A Night at the Opera",
                "duration": 355,
                "instrumental": false,
                "plainLyrics": "Is this the real life?",
                "syncedLyrics": "[00:00.00] Is this the real life?"
            }
        ]
        """
        let searchResponse = HTTPURLResponse(url: URL(string: "https://lrclib.net/api/search")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        session.responses = [
            (Data(), getResponse, nil),
            (searchJson.data(using: .utf8)!, searchResponse, nil)
        ]
        
        let result = await repository.fetchBestLyrics(for: track)
        
        XCTAssertEqual(result.lyrics.artistName, "Queen")
        XCTAssertTrue(result.lyrics.isSynced)
        XCTAssertTrue(cache.didCache)
    }
    
    func testFetchBestLyrics_SearchEmpty() async throws {
        let track = Track(artist: "Unknown", title: "Unknown", duration: 355, elapsedTime: 0, isPlaying: true, lastUpdatedTime: 0)
        
        let notFoundResponse = HTTPURLResponse(url: URL(string: "https://lrclib.net/api")!, statusCode: 404, httpVersion: nil, headerFields: nil)!
        let searchResponse = HTTPURLResponse(url: URL(string: "https://lrclib.net/api/search")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        session.responses = [
            (Data(), notFoundResponse, nil),
            ("[]".data(using: .utf8)!, searchResponse, nil)
        ]
        
        let result = await repository.fetchBestLyrics(for: track)
        
        XCTAssertEqual(result.lyrics.artistName, "Unknown")
        XCTAssertFalse(result.lyrics.isSynced)
        XCTAssertTrue(result.lyrics.lines.isEmpty)
    }
}
