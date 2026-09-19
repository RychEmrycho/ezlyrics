import Testing
import Foundation
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

@Suite struct LRCLIBClientTests {
    var session: MockURLSession!
    var sut: LRCLIBClient!
    
    init() {
        session = MockURLSession()
        sut = LRCLIBClient(session: session)
    }
    

    
    @Test func GetLyricsSuccess() async throws {
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
        
        #expect(response.trackName == "Test Track")
        #expect(response.plainLyrics == "Test Lyrics")
        #expect(response.syncedLyrics == "[00:10.00]Test Lyrics")
        
        // Check query items
        let url = try #require(session.lastRequest?.url)
        #expect(url.absoluteString.contains("artist_name=Test%20Artist"))
        #expect(url.absoluteString.contains("track_name=Test%20Track"))
        #expect(url.absoluteString.contains("duration=200"))
    }
    
    @Test func GetLyricsNotFound() async {
        session.stubbedResponse = HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 404, httpVersion: nil, headerFields: nil)
        
        do {
            _ = try await sut.getLyrics(artist: "Unknown", title: "Unknown", duration: 0)
            Issue.record("Expected to throw notFound error")
        } catch let error as LRCLIBError {
            if case .notFound = error {
                // Success
            } else {
                Issue.record("Expected notFound error, got \(error)")
            }
        } catch {
            Issue.record("Expected LRCLIBError, got \(error)")
        }
    }
}
