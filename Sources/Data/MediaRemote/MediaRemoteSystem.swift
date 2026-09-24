import Foundation

@MainActor
class MediaRemoteSystem: NowPlayingProvider {
    
    private var process: Process?
    private var latestTrack: Track?
    var onTrackChanged: ((Track?) -> Void)?
    
    func stop() {
        process?.terminate()
        process = nil
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

        nonisolated(unsafe) var lastRawElapsedTime: Double = -1
        nonisolated(unsafe) var isDynamic = false

        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            getInfo(DispatchQueue.main) { info in
                let artist = (info["kMRMediaRemoteNowPlayingInfoArtist"] as? String) ?? ""
                let title = (info["kMRMediaRemoteNowPlayingInfoTitle"] as? String) ?? ""
                let duration = (info["kMRMediaRemoteNowPlayingInfoDuration"] as? NSNumber)?.doubleValue ?? 0
                let rawElapsedTime = (info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? NSNumber)?.doubleValue ?? 0
                let rate = (info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? NSNumber)?.doubleValue ?? 0
                let timestampDate = info["kMRMediaRemoteNowPlayingInfoTimestamp"] as? Date
                
                if lastRawElapsedTime != -1 {
                    if rawElapsedTime != lastRawElapsedTime {
                        isDynamic = true
                    } else if rate > 0 {
                        isDynamic = false
                    }
                }
                lastRawElapsedTime = rawElapsedTime
                
                var trueElapsedTime = rawElapsedTime
                if !isDynamic, let tDate = timestampDate, rate > 0 {
                    trueElapsedTime += Date().timeIntervalSince(tDate)
                }
                
                print("\\(artist)||\\(title)||\\(duration)||\\(trueElapsedTime)||\\(rate)")
                fflush(stdout)
            }
        }
        RunLoop.main.run()
        """
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        process.arguments = ["-e", script]
        
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
    
    private func sendMediaKey(_ key: Int) {
        let script = """
        import AppKit

        func postMediaKey(key: Int, down: Bool) {
            let flags: NSEvent.ModifierFlags = down ? NSEvent.ModifierFlags(rawValue: 0xa00) : NSEvent.ModifierFlags(rawValue: 0xb00)
            let data1 = (key << 16) | (down ? 0xa00 : 0xb00)
            
            if let event = NSEvent.otherEvent(
                with: .systemDefined,
                location: .zero,
                modifierFlags: flags,
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                subtype: 8,
                data1: data1,
                data2: -1
            ) {
                let cgEvent = event.cgEvent
                cgEvent?.post(tap: .cghidEventTap)
            }
        }
        postMediaKey(key: \(key), down: true)
        postMediaKey(key: \(key), down: false)
        """
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        process.arguments = ["-e", script]
        try? process.run()
    }
    
    func togglePlayPause() {
        AppLogger.mediaRemote.debug("Toggling Play/Pause")
        sendMediaKey(16) // NX_KEYTYPE_PLAY
    }
    
    func nextTrack() {
        AppLogger.mediaRemote.debug("Skipping to next track")
        sendMediaKey(17) // NX_KEYTYPE_NEXT
    }
    
    func previousTrack() {
        AppLogger.mediaRemote.debug("Skipping to previous track")
        sendMediaKey(18) // NX_KEYTYPE_PREVIOUS
    }
    
    nonisolated private func parseLine(_ line: String) {
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
            
            let track = Track(
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
