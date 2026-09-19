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
        
        print("\(artist)||\(title)||\(duration)||\(trueElapsedTime)||\(rate)")
        fflush(stdout)
    }
}
RunLoop.main.run()
