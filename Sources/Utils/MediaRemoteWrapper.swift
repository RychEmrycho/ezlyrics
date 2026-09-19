import Foundation

struct NowPlayingTrack: Equatable {
    var artist: String
    var title: String
    var duration: TimeInterval
    var elapsedTime: TimeInterval
    var isPlaying: Bool
    var lastUpdatedTime: TimeInterval
}

class MediaRemoteWrapper: @unchecked Sendable {
    
    static let shared = MediaRemoteWrapper()
    
    private var process: Process?
    private var latestTrack: NowPlayingTrack?
    var onTrackChanged: ((NowPlayingTrack?) -> Void)?
    
    private init() {
        // Will be started explicitly based on settings
    }
    
    func stopHelper() {
        process?.terminate()
        process = nil
        latestTrack = nil
        onTrackChanged?(nil)
    }
    
    func startHelper() {
        guard process == nil else { return }
        guard let scriptURL = Bundle.module.url(forResource: "MediaRemoteHelper", withExtension: "swift", subdirectory: "Scripts") else {
            print("Failed to find MediaRemoteHelper.swift in bundle.")
            return
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        process.arguments = [scriptURL.path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let str = String(data: data, encoding: .utf8) else { return }
            
            let lines = str.components(separatedBy: .newlines).filter { !$0.isEmpty }
            for line in lines {
                self?.parseLine(line)
            }
        }
        
        try? process.run()
        self.process = process
    }
    
    private func parseLine(_ line: String) {
        let parts = line.components(separatedBy: "||")
        guard parts.count >= 5 else { return }
        
        let rawArtist = parts[0]
        let rawTitle = parts[1]
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if rawArtist.isEmpty && rawTitle.isEmpty {
                self.latestTrack = nil
                self.onTrackChanged?(nil)
                return
            }
            
            var artist = rawArtist
            var title = rawTitle
            
            // Japanese YouTube parsing: e.g. "KANA-BOON 『ないものねだり』Music Video"
            let jpRegex = try? NSRegularExpression(pattern: "『(.*?)』|「(.*?)」")
            if let regex = jpRegex, let match = regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)) {
                let fullMatchRange = Range(match.range, in: title)!
                let prefixStr = title[..<fullMatchRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let range1 = Range(match.range(at: 1), in: title) {
                    title = String(title[range1])
                } else if let range2 = Range(match.range(at: 2), in: title) {
                    title = String(title[range2])
                }
                
                if !prefixStr.isEmpty {
                    artist = prefixStr
                }
            } else if title.contains(" - ") {
                let titleParts = title.components(separatedBy: " - ")
                if titleParts.count >= 2 {
                    let firstPart = titleParts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let secondPart = titleParts.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Always use the title split as the source of truth for Artist and Title when available
                    // Because YouTube channel names are often networks or have "VEVO" appended
                    artist = firstPart
                    title = secondPart
                }
            }
            
            // Strip junk tags that ruin lyrics searches like (Lyrics), [Official Music Video], etc.
            let cleanTitle = title.replacingOccurrences(of: "(?i)\\s*\\(.*?official.*?\\)|\\s*\\[.*?official.*?\\]|\\s*\\(.*?lyrics.*?\\)|\\s*\\[.*?lyrics.*?\\]", with: "", options: .regularExpression)
            title = cleanTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let duration = Double(parts[2]) ?? 0
            let elapsedTime = Double(parts[3]) ?? 0
            let rate = Double(parts[4]) ?? 0
            
            let track = NowPlayingTrack(
                artist: artist,
                title: title,
                duration: duration,
                elapsedTime: elapsedTime,
                isPlaying: rate > 0,
                lastUpdatedTime: Date().timeIntervalSinceReferenceDate
            )
            
            self.latestTrack = track
            self.onTrackChanged?(track)
        }
    }
}
