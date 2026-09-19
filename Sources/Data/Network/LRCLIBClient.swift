import Foundation

enum LRCLIBError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case notFound
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .networkError(let error): return "Network Error: \(error.localizedDescription)"
        case .notFound: return "Lyrics not found"
        case .decodingError(let error): return "Failed to decode lyrics: \(error.localizedDescription)"
        }
    }
}

protocol URLSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

final class LRCLIBClient: Sendable {
    private let baseURL = "https://lrclib.net/api"
    private let session: URLSessionProtocol
    
    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }
    
    func getLyrics(artist: String, title: String, duration: TimeInterval) async throws -> LRCLIBResponse {
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
            return try JSONDecoder().decode(LRCLIBResponse.self, from: data)
        } catch {
            throw LRCLIBError.decodingError(error)
        }
    }
    
    func searchLyrics(query: String) async throws -> [LRCLIBResponse] {
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
            return try JSONDecoder().decode([LRCLIBResponse].self, from: data)
        } catch {
            throw LRCLIBError.decodingError(error)
        }
    }
}
