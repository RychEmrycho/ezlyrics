import Foundation


final class LRCLIBClient: LyricProvider {
    static let shared = LRCLIBClient()
    
    let name = "LRCLIB"
    
    private let baseURL = "https://lrclib.net/api"
    private let session: URLSessionProtocol
    
    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }
    
    func getLyrics(artist: String, title: String, duration: TimeInterval) async throws -> ParsedLyrics {
        var components = URLComponents(string: "\(baseURL)/get")!
        var queryItems = [
            URLQueryItem(name: "artist_name", value: artist),
            URLQueryItem(name: "track_name", value: title)
        ]
        if duration > 0 {
            queryItems.append(URLQueryItem(name: "duration", value: String(Int(duration))))
        }
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw LRCLIBError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("ezlyrics/1.0 (https://github.com/emrycho/ezlyrics)", forHTTPHeaderField: "User-Agent")
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw LRCLIBError.networkError(error)
        }
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw LRCLIBError.notFound
        }
        
        do {
            let apiResponse = try JSONDecoder().decode(LRCLIBResponse.self, from: data)
            return LRCParser.parse(plain: apiResponse.plainLyrics, synced: apiResponse.syncedLyrics, trackName: apiResponse.trackName, artistName: apiResponse.artistName, sourceID: String(apiResponse.id))
        } catch {
            throw LRCLIBError.decodingError(error)
        }
    }
    
    func searchLyrics(query: String) async throws -> [LyricSearchResult] {
        var components = URLComponents(string: "\(baseURL)/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query)
        ]
        
        guard let url = components.url else {
            throw LRCLIBError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("ezlyrics/1.0 (https://github.com/emrycho/ezlyrics)", forHTTPHeaderField: "User-Agent")
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw LRCLIBError.networkError(error)
        }
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw LRCLIBError.notFound
        }
        
        do {
            let apiResponses = try JSONDecoder().decode([LRCLIBResponse].self, from: data)
            return apiResponses.map {
                LyricSearchResult(
                    id: String($0.id),
                    trackName: $0.trackName,
                    artistName: $0.artistName,
                    duration: $0.duration,
                    hasSyncedLyrics: $0.syncedLyrics != nil,
                    hasPlainLyrics: $0.plainLyrics != nil,
                    providerName: self.name
                )
            }
        } catch {
            throw LRCLIBError.decodingError(error)
        }
    }
    
    func fetchLyrics(for searchResult: LyricSearchResult) async throws -> ParsedLyrics {
        guard let url = URL(string: "\(baseURL)/get/\(searchResult.id)") else {
            throw LRCLIBError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("ezlyrics/1.0 (https://github.com/emrycho/ezlyrics)", forHTTPHeaderField: "User-Agent")
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw LRCLIBError.networkError(error)
        }
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw LRCLIBError.notFound
        }
        
        do {
            let apiResponse = try JSONDecoder().decode(LRCLIBResponse.self, from: data)
            return LRCParser.parse(plain: apiResponse.plainLyrics, synced: apiResponse.syncedLyrics, trackName: apiResponse.trackName, artistName: apiResponse.artistName, sourceID: String(apiResponse.id))
        } catch {
            throw LRCLIBError.decodingError(error)
        }
    }
}
