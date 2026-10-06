import Foundation

public struct GitHubRelease: Codable, Sendable {
    public let tagName: String
    public let htmlUrl: String
    
    public enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlUrl = "html_url"
    }
}
