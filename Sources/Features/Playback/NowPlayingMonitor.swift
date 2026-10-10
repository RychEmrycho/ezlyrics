import Foundation
import Combine

@MainActor
class NowPlayingMonitor: ObservableObject {
    @Published var currentTrack: Track?
    
    private let provider: NowPlayingProvider
    
    init(provider: NowPlayingProvider) {
        self.provider = provider
        startListening()
    }
    
    private func startListening() {
        provider.onTrackChanged = { [weak self] track in
            self?.handleTrackUpdate(track)
        }
    }
    
    private func handleTrackUpdate(_ track: Track?) {
        // If track changed (different song, or user scrubbed/drifted > 0.1s, or play/pause state changed)
        if let newTrack = track {
            if let current = self.currentTrack {
                let isDifferentSong = !current.isSameSong(as: newTrack)
                let stateChanged = newTrack.isPlaying != current.isPlaying
                
                // We interpolate the expected time to see if the user scrubbed or the player corrected its timing
                let timeSinceLastUpdate = newTrack.lastUpdatedTime - current.lastUpdatedTime
                let expectedElapsed = current.isPlaying ? current.elapsedTime + timeSinceLastUpdate : current.elapsedTime
                let drift = abs(expectedElapsed - newTrack.elapsedTime)
                
                if isDifferentSong || stateChanged || drift > 0.02 {
                    self.currentTrack = newTrack
                }
            } else {
                self.currentTrack = newTrack
            }
        } else {
            if self.currentTrack != nil {
                self.currentTrack = nil
            }
        }
    }
}
