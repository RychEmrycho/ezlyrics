import Foundation

@MainActor
class MediaRemoteSystem: NowPlayingProvider {
    
    private var process: Process?
    private var stdoutPipe: Pipe?
    private var latestTrack: Track?
    var onTrackChanged: ((Track?) -> Void)?
    
    /// Stop is called explicitly by the coordinator. deinit doesn't need to clean up
    /// because the subprocess will be terminated when the app exits.
    func stop() {
        stdoutPipe?.fileHandleForReading.readabilityHandler = nil
        process?.terminate()
        process = nil
        stdoutPipe = nil
        latestTrack = nil
        onTrackChanged?(nil)
    }
    
    func start() {
        guard process == nil else { return }
        
        let script = """
        import Foundation

        let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))
        guard let bundle = bundle else { exit(1) }
        let pointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString)
        typealias InfoFunc = @convention(c) (DispatchQueue, @escaping @convention(block) ([String: Any]) -> Void) -> Void
        let getInfo = unsafeBitCast(pointer, to: InfoFunc.self)

        let timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            getInfo(DispatchQueue.main) { info in
                let artist = (info["kMRMediaRemoteNowPlayingInfoArtist"] as? String) ?? ""
                let title = (info["kMRMediaRemoteNowPlayingInfoTitle"] as? String) ?? ""
                let duration = (info["kMRMediaRemoteNowPlayingInfoDuration"] as? NSNumber)?.doubleValue ?? 0
                let rawElapsedTime = (info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? NSNumber)?.doubleValue ?? 0
                let rate = (info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? NSNumber)?.doubleValue ?? 0
                let curDate = (info["kMRMediaRemoteNowPlayingInfoCurrentPlaybackDate"] as? Date)?.timeIntervalSinceReferenceDate
                let ts = (info["kMRMediaRemoteNowPlayingInfoTimestamp"] as? Date)?.timeIntervalSinceReferenceDate ?? -1
                let timestamp: Double
                if let curDate = curDate, ts != -1, abs(ts - curDate) < 5.0 {
                    timestamp = curDate
                } else {
                    timestamp = ts
                }
                print("\\(artist)||\\(title)||\\(duration)||\\(rawElapsedTime)||\\(rate)||\\(timestamp)")
                fflush(stdout)
            }
        }

        RunLoop.main.run()
        """
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        process.arguments = ["-e", script]
        
        // Pipe stdout for now-playing data
        let outPipe = Pipe()
        process.standardOutput = outPipe
        
        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let str = String(data: data, encoding: .utf8) else { return }
            
            let lines = str.components(separatedBy: .newlines).filter { !$0.isEmpty }
            for line in lines {
                self?.parseLine(line)
            }
        }
        
        try? process.run()
        self.process = process
        self.stdoutPipe = outPipe
    }
    
    // MARK: - Sending media playback commands via MediaRemote
    
    private lazy var sendMediaRemoteCommand: (@convention(c) (Int, AnyObject?) -> Bool)? = {
        let path = "/System/Library/PrivateFrameworks/MediaRemote.framework" as CFString
        let url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, path, .cfurlposixPathStyle, true)
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, url) else { return nil }
        guard let ptr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSendCommand" as CFString) else { return nil }
        typealias SendCommandFunc = @convention(c) (Int, AnyObject?) -> Bool
        return unsafeBitCast(ptr, to: SendCommandFunc.self)
    }()
    
    func togglePlayPause() {
        AppLogger.mediaRemote.debug("Toggling Play/Pause")
        _ = sendMediaRemoteCommand?(2, nil) // kMRTogglePlayPause
    }
    
    func nextTrack() {
        AppLogger.mediaRemote.debug("Skipping to next track")
        _ = sendMediaRemoteCommand?(4, nil) // kMRNextTrack
    }
    
    func previousTrack() {
        AppLogger.mediaRemote.debug("Skipping to previous track")
        _ = sendMediaRemoteCommand?(5, nil) // kMRPreviousTrack
    }
    
    nonisolated private func parseLine(_ line: String) {
        let parts = line.components(separatedBy: "||")
        guard parts.count >= 6 else { return }
        
        let rawArtist = parts[0]
        let rawTitle = parts[1]
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if rawArtist.isEmpty && rawTitle.isEmpty {
                self.latestTrack = nil
                self.onTrackChanged?(nil)
                return
            }
            
            let parsed = TrackMetadataParser.parse(rawArtist: rawArtist, rawTitle: rawTitle)
            let duration = Double(parts[2]) ?? 0
            let rawElapsedTime = Double(parts[3]) ?? 0
            let rate = Double(parts[4]) ?? 0
            let timestampInterval = Double(parts[5]) ?? -1
            
            var trueElapsedTime = rawElapsedTime
            if timestampInterval != -1 && rate > 0 {
                trueElapsedTime += max(0, Date().timeIntervalSinceReferenceDate - timestampInterval)
            }
            
            let track = Track(
                artist: parsed.artist,
                title: parsed.title,
                duration: duration,
                elapsedTime: trueElapsedTime,
                isPlaying: rate > 0,
                lastUpdatedTime: Date().timeIntervalSinceReferenceDate
            )
            
            self.latestTrack = track
            self.onTrackChanged?(track)
        }
    }
}
