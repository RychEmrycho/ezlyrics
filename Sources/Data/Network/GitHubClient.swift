import Foundation

public enum GitHubClientError: Error {
    case invalidURL
    case invalidResponse
    case rateLimitExceeded
    case requestFailed(statusCode: Int)
}

public struct GitHubClient: UpdateProvider {
    private let repoURL = "https://api.github.com/repos/RychEmrycho/ezlyrics/releases/latest"
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func fetchLatestRelease() async throws -> GitHubRelease {
        guard let url = URL(string: repoURL) else {
            throw GitHubClientError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubClientError.invalidResponse
        }
        
        if httpResponse.statusCode == 403 {
            throw GitHubClientError.rateLimitExceeded
        }
        
        guard httpResponse.statusCode == 200 else {
            throw GitHubClientError.requestFailed(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }
}
