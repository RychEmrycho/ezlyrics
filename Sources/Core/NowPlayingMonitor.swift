import Foundation
import Combine

@MainActor
class NowPlayingMonitor: ObservableObject {
    @Published var currentTrack: NowPlayingTrack?
    
    private var timer: Timer?
    
    init() {
        startPolling()
    }
    
    func startPolling() {
        // Poll every 1 second to detect track changes or scrub events
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
    }
    
    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
    
    private func poll() {
        MediaRemoteWrapper.shared.fetchNowPlaying { [weak self] track in
            DispatchQueue.main.async {
                // If track changed (different song, or user scrubbed > 2s, or play/pause state changed)
                if let newTrack = track {
                    if let current = self?.currentTrack {
                        let isDifferentSong = newTrack.title != current.title || newTrack.artist != current.artist
                        let stateChanged = newTrack.isPlaying != current.isPlaying
                        
                        // We interpolate the expected time to see if the user scrubbed
                        let timeSinceLastUpdate = newTrack.lastUpdatedTime - current.lastUpdatedTime
                        let expectedElapsed = current.isPlaying ? current.elapsedTime + timeSinceLastUpdate : current.elapsedTime
                        let drift = abs(expectedElapsed - newTrack.elapsedTime)
                        
                        if isDifferentSong || stateChanged || drift > 2.0 {
                            self?.currentTrack = newTrack
                        }
                    } else {
                        self?.currentTrack = newTrack
                    }
                } else {
                    if self?.currentTrack != nil {
                        self?.currentTrack = nil
                    }
                }
            }
        }
    }
}
