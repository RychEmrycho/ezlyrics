import Foundation

enum OvhLyricsError: Error, LocalizedError {
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
