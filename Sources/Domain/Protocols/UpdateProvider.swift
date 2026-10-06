import Foundation

public protocol UpdateProvider: Sendable {
    func fetchLatestRelease() async throws -> GitHubRelease
}
