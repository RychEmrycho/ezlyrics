import Foundation


final class OvhLyricsClient: LyricProvider {
    static let shared = OvhLyricsClient()
    
    let name = "Lyrics.ovh"
    private let baseURL = "https://api.lyrics.ovh/v1"
    private let session: URLSessionProtocol
    
    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }
    
    func getLyrics(artist: String, title: String, duration: TimeInterval) async throws -> ParsedLyrics {
        guard let encodedArtist = artist.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/\(encodedArtist)/\(encodedTitle)") else {
            throw OvhLyricsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("ezlyrics/1.0", forHTTPHeaderField: "User-Agent")
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw OvhLyricsError.networkError(error)
        }
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw OvhLyricsError.notFound
        }
        
        do {
            let apiResponse = try JSONDecoder().decode(OvhLyricsResponse.self, from: data)
            
            var cleanedLyrics = apiResponse.lyrics
            if cleanedLyrics.starts(with: "Paroles de la chanson") {
                if let index = cleanedLyrics.firstIndex(of: "\n") {
                    let nextIndex = cleanedLyrics.index(after: index)
                    cleanedLyrics = String(cleanedLyrics[nextIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            let lines = cleanedLyrics.components(separatedBy: .newlines).map {
                LyricLine(timestamp: 0, text: $0, syllables: nil)
            }
            
            return ParsedLyrics(
                trackName: title,
                artistName: artist,
                isSynced: false,
                lines: lines,
                detectedLanguage: nil, // We could run language detection here, but we'll skip for brevity
                sourceID: UUID().uuidString,
                originalResponse: nil
            )
        } catch {
            throw OvhLyricsError.decodingError(error)
        }
    }
    
    func searchLyrics(query: String) async throws -> [LyricSearchResult] {
        return []
    }
    
    func fetchLyrics(for searchResult: LyricSearchResult) async throws -> ParsedLyrics {
        // Since search is not supported, this shouldn't be called, but we can implement it by parsing the track name and artist name from the result
        return try await getLyrics(artist: searchResult.artistName, title: searchResult.trackName, duration: searchResult.duration ?? 0)
    }
}
