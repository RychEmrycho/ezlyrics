import Foundation

class MediaRemoteSystem: @unchecked Sendable {
    
    static let shared = MediaRemoteSystem()
    
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
            
            // Delegate all metadata parsing to TrackMetadataParser
            let parsed = TrackMetadataParser.parse(rawArtist: rawArtist, rawTitle: rawTitle)
            
            let duration = Double(parts[2]) ?? 0
            let elapsedTime = Double(parts[3]) ?? 0
            let rate = Double(parts[4]) ?? 0
            
            let track = NowPlayingTrack(
                artist: parsed.artist,
                title: parsed.title,
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
