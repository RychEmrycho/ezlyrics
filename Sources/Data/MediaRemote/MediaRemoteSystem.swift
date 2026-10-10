import Foundation
import AppKit

@MainActor
class MediaRemoteSystem: NowPlayingProvider {
    
    private var process: Process?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private var outputBuffer: String = ""
    private var latestTrack: Track?
    var onTrackChanged: ((Track?) -> Void)?
    
    func stop() {
        stdoutPipe?.fileHandleForReading.readabilityHandler = nil
        stderrPipe?.fileHandleForReading.readabilityHandler = nil
        if let proc = process {
            proc.terminationHandler = nil
            proc.terminate()
        }
        process = nil
        stdoutPipe = nil
        stderrPipe = nil
        outputBuffer = ""
        latestTrack = nil
        onTrackChanged?(nil)
    }
    
    func start() {
        guard process == nil else { return }
        
        let script = """
        import Foundation

        let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))
        guard let bundle = bundle else {
            fputs("Failed to load MediaRemote.framework\\n", stderr)
            exit(1)
        }
        let pointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString)
        guard let pointer = pointer else {
            fputs("Failed to locate MRMediaRemoteGetNowPlayingInfo\\n", stderr)
            exit(2)
        }
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
        
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        
        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let str = String(data: data, encoding: .utf8) else { return }
            
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.outputBuffer += str
                while let newlineRange = self.outputBuffer.range(of: "\n") {
                    let line = String(self.outputBuffer[..<newlineRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    self.outputBuffer = String(self.outputBuffer[newlineRange.upperBound...])
                    if !line.isEmpty {
                        self.parseLine(line)
                    }
                }
            }
        }
        
        errPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let str = String(data: data, encoding: .utf8) else { return }
            let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                AppLogger.mediaRemote.error("MediaRemote helper error: \(trimmed)")
            }
        }
        
        process.terminationHandler = { [weak self] proc in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if self.process === proc {
                    AppLogger.mediaRemote.warning("MediaRemote helper exited with status \(proc.terminationStatus). Scheduling restart...")
                    self.stop()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        if UserPreferences.shared.isAppEnabled {
                            self.start()
                        }
                    }
                }
            }
        }
        
        do {
            try process.run()
            self.process = process
            self.stdoutPipe = outPipe
            self.stderrPipe = errPipe
            AppLogger.mediaRemote.info("Started MediaRemote helper (PID: \(process.processIdentifier))")
        } catch {
            AppLogger.mediaRemote.error("Failed to run MediaRemote helper process: \(error.localizedDescription)")
            self.process = nil
            self.stdoutPipe = nil
            self.stderrPipe = nil
        }
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
    
    private func postMediaKeyEvent(key: Int) {
        func postKey(down: Bool) {
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
                event.cgEvent?.post(tap: .cghidEventTap)
            }
        }
        postKey(down: true)
        postKey(down: false)
    }
    
    func togglePlayPause() {
        AppLogger.mediaRemote.debug("Toggling Play/Pause")
        let success = sendMediaRemoteCommand?(2, nil) ?? false
        if !success {
            postMediaKeyEvent(key: 16) // NX_KEYTYPE_PLAY fallback
        }
    }
    
    func nextTrack() {
        AppLogger.mediaRemote.debug("Skipping to next track")
        let success = sendMediaRemoteCommand?(4, nil) ?? false
        if !success {
            postMediaKeyEvent(key: 17) // NX_KEYTYPE_NEXT fallback
        }
    }
    
    func previousTrack() {
        AppLogger.mediaRemote.debug("Skipping to previous track")
        let success = sendMediaRemoteCommand?(5, nil) ?? false
        if !success {
            postMediaKeyEvent(key: 18) // NX_KEYTYPE_PREVIOUS fallback
        }
    }
    
    private func parseLine(_ line: String) {
        let parts = line.components(separatedBy: "||")
        guard parts.count >= 5 else { return }
        
        let rawArtist = parts[0]
        let rawTitle = parts[1]
        
        if rawArtist.isEmpty && rawTitle.isEmpty {
            if self.latestTrack != nil {
                self.latestTrack = nil
                self.onTrackChanged?(nil)
            }
            return
        }
        
        let parsed = TrackMetadataParser.parse(rawArtist: rawArtist, rawTitle: rawTitle)
        let duration = Double(parts[2]) ?? 0
        let rawElapsedTime = Double(parts[3]) ?? 0
        let rate = Double(parts[4]) ?? 0
        let timestampInterval = parts.count >= 6 ? (Double(parts[5]) ?? -1) : -1
        
        var trueElapsedTime = rawElapsedTime
        if timestampInterval != -1 && rate > 0 {
            trueElapsedTime += max(0, Date().timeIntervalSinceReferenceDate - timestampInterval)
        }
        
        let isDifferent = latestTrack == nil || latestTrack?.title != parsed.title || latestTrack?.artist != parsed.artist || latestTrack?.isPlaying != (rate > 0)
        if isDifferent {
            AppLogger.mediaRemote.info("Detected track: \(parsed.artist) - \(parsed.title) (playing: \(rate > 0))")
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
