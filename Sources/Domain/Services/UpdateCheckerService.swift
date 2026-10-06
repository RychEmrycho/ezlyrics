import Foundation
import Cocoa

@MainActor
final class UpdateCheckerService: ObservableObject {
    static let shared = UpdateCheckerService()
    
    @Published var isChecking = false
    @Published var updateAvailable = false
    @Published var latestVersion = ""
    @Published var releaseURL: URL?
    
    private var timer: Timer?
    private let repoURL = "https://api.github.com/repos/RychEmrycho/ezlyrics/releases/latest"
    
    // Auto-update configuration
    private let timerInterval: TimeInterval = 12 * 60 * 60 // 12 hours
    private let minimumTimeBetweenChecks: TimeInterval = 24 * 60 * 60 // 24 hours
    
    private init() {}
    
    struct GitHubRelease: Codable {
        let tagName: String
        let htmlUrl: String
        
        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlUrl = "html_url"
        }
    }
    
    func startDailyCheck() {
        // Run immediately in background if enough time has passed
        Task {
            await checkForUpdates(silent: true)
        }
        
        // Then set up a timer to check periodically
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.checkForUpdates(silent: true)
            }
        }
    }
    
    func checkForUpdates(silent: Bool = false) async {
        if silent {
            // Respect the user's preference if they toggle it off while the app is running
            if !UserPreferences.shared.checkForUpdatesAutomatically {
                return
            }
            
            let now = Date().timeIntervalSince1970
            let lastCheck = UserPreferences.shared.lastUpdateCheckTimestamp
            if (now - lastCheck) < minimumTimeBetweenChecks {
                return // Too soon to check again automatically
            }
        }
        
        isChecking = true
        defer { isChecking = false }
        
        guard let url = URL(string: repoURL) else { return }
        
        AppLogger.shared.info("Checking for updates (silent: \(silent))...")
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        // Short timeout for background checks
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                AppLogger.shared.error("Invalid response from GitHub API.")
                if !silent {
                    showError(message: "Invalid response from server.")
                }
                return
            }
            
            // Handle GitHub rate limiting specifically
            if httpResponse.statusCode == 403 {
                AppLogger.shared.warning("GitHub API rate limit exceeded.")
                if !silent {
                    showError(message: "GitHub API rate limit exceeded. Please try again later.")
                }
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                AppLogger.shared.error("Failed to connect to GitHub API. Status: \(httpResponse.statusCode)")
                if !silent {
                    showError(message: "Failed to connect to GitHub API. (Status: \(httpResponse.statusCode))")
                }
                return
            }
            
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let latestTag = release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
            
            // Record check time on success
            if silent {
                UserPreferences.shared.lastUpdateCheckTimestamp = Date().timeIntervalSince1970
            }
            
            if isNewerVersion(latest: latestTag, current: currentVersion) {
                AppLogger.shared.info("New update available: \(latestTag) (Current: \(currentVersion))")
                updateAvailable = true
                latestVersion = release.tagName
                releaseURL = URL(string: release.htmlUrl)
                
                if !silent {
                    showUpdateAlert(version: release.tagName, url: release.htmlUrl)
                }
            } else {
                AppLogger.shared.info("App is up to date (Current: \(currentVersion))")
                updateAvailable = false
                if !silent {
                    showUpToDateAlert()
                }
            }
            
        } catch {
            AppLogger.shared.error("Failed to check for updates: \(error)")
            if !silent {
                showError(message: error.localizedDescription)
            }
        }
    }
    
    private func isNewerVersion(latest: String, current: String) -> Bool {
        let latestParts = latest.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<max(latestParts.count, currentParts.count) {
            let l = i < latestParts.count ? latestParts[i] : 0
            let c = i < currentParts.count ? currentParts[i] : 0
            
            if l > c { return true }
            if l < c { return false }
        }
        return false
    }
    
    private func showUpdateAlert(version: String, url: String) {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "A new version of ezlyrics (\(version)) is available. Would you like to download it now?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")
        
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let targetURL = URL(string: url) {
                NSWorkspace.shared.open(targetURL)
            }
        }
    }
    
    private func showUpToDateAlert() {
        let alert = NSAlert()
        alert.messageText = "Up to Date"
        alert.informativeText = "You are running the latest version of ezlyrics."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
    
    private func showError(message: String) {
        let alert = NSAlert()
        alert.messageText = "Update Check Failed"
        alert.informativeText = "Could not check for updates.\n\(message)"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
