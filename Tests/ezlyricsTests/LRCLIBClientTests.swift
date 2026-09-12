import XCTest
@testable import ezlyrics

final class MockURLSession: URLSessionProtocol, @unchecked Sendable {
    var stubbedData: Data?
    var stubbedResponse: URLResponse?
    var stubbedError: Error?
    
    var lastRequest: URLRequest?
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        
        if let error = stubbedError {
            throw error
        }
        
        let data = stubbedData ?? Data()
        let response = stubbedResponse ?? HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        return (data, response)
    }
}

final class LRCLIBClientTests: XCTestCase {
    var session: MockURLSession!
    var sut: LRCLIBClient!
    
    override func setUp() {
        super.setUp()
        session = MockURLSession()
        sut = LRCLIBClient(session: session)
    }
    
    override func tearDown() {
        session = nil
        sut = nil
        super.tearDown()
    }
    
    func testGetLyricsSuccess() async throws {
        let jsonString = """
        {
            "id": 1,
            "trackName": "Test Track",
            "artistName": "Test Artist",
            "albumName": "Test Album",
            "duration": 200,
            "instrumental": false,
            "plainLyrics": "Test Lyrics",
            "syncedLyrics": "[00:10.00]Test Lyrics"
        }
        """
        session.stubbedData = jsonString.data(using: .utf8)
        
        let response = try await sut.getLyrics(artist: "Test Artist", title: "Test Track", duration: 200)
        
        XCTAssertEqual(response.trackName, "Test Track")
        XCTAssertEqual(response.plainLyrics, "Test Lyrics")
        XCTAssertEqual(response.syncedLyrics, "[00:10.00]Test Lyrics")
        
        // Check query items
        let url = try XCTUnwrap(session.lastRequest?.url)
        XCTAssertTrue(url.absoluteString.contains("artist_name=Test%20Artist"))
        XCTAssertTrue(url.absoluteString.contains("track_name=Test%20Track"))
        XCTAssertTrue(url.absoluteString.contains("duration=200"))
    }
    
    func testGetLyricsNotFound() async {
        session.stubbedResponse = HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 404, httpVersion: nil, headerFields: nil)
        
        do {
            _ = try await sut.getLyrics(artist: "Unknown", title: "Unknown", duration: 0)
            XCTFail("Expected to throw notFound error")
        } catch let error as LRCLIBError {
            if case .notFound = error {
                // Success
            } else {
                XCTFail("Expected notFound error, got \(error)")
            }
        } catch {
            XCTFail("Expected LRCLIBError, got \(error)")
        }
    }
}
