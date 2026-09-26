import SwiftUI

struct PlaybackProgressBar: View {
    let track: Track
    @ObservedObject var playbackVM: PlaybackViewModel
    @State private var elapsed: TimeInterval = 0
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                let total = max(track.duration, 1)
                let percent = max(0, min(1, elapsed / total))
                let fillWidth = geo.size.width * percent
                
                ZStack(alignment: .leading) {
                    // Track line (grey)
                    Capsule()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 4)
                    
                    // Running line (primary: white in dark, dark in light)
                    Capsule()
                        .fill(Color.primary)
                        .frame(width: fillWidth, height: 4)
                    
                    // Thumb circle
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 8, height: 8)
                        .offset(x: max(0, fillWidth - 4))
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 8)
            
            HStack {
                Text(formatTime(elapsed))
                Spacer()
                Text(formatTime(track.duration))
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(.secondary)
        }
        .onReceive(timer) { _ in
            elapsed = min(playbackVM.currentPlaybackTime(), track.duration)
        }
        .onAppear {
            elapsed = min(playbackVM.currentPlaybackTime(), track.duration)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && !time.isNaN else { return "0:00" }
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct MenuBarNowPlayingHeader: View {
    @ObservedObject var playbackVM: PlaybackViewModel
    @State private var isHoveringPlay = false
    @State private var isHoveringPrev = false
    @State private var isHoveringNext = false
    
    var body: some View {
        VStack(spacing: 12) {
            if let track = playbackVM.currentTrack {
                // Horizontal Layout: Info on Left, Controls on Right
                HStack(alignment: .center, spacing: 12) {
                    // Track Info
                    VStack(alignment: .leading, spacing: 2) {
                        MarqueeText(text: track.title, font: .headline)
                        MarqueeText(text: track.artist, font: .subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer(minLength: 0)
                    
                    // Controls
                    HStack(spacing: 12) {
                        Button(action: {
                            AppLogger.ui.debug("Tapped previous track button")
                            playbackVM.previousTrack?()
                        }) {
                            Image(systemName: "backward.fill")
                                .font(.body)
                                .foregroundColor(isHoveringPrev ? .primary : .secondary)
                                .frame(width: 28, height: 28)
                                .background(isHoveringPrev ? Color.primary.opacity(0.1) : Color.clear)
                                .clipShape(Circle())
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .onHover { isHoveringPrev = $0 }
                        .help("Previous Track")
                        
                        Button(action: {
                            AppLogger.ui.debug("Tapped play/pause button")
                            playbackVM.togglePlayPause?()
                        }) {
                            Image(systemName: track.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title3)
                                .foregroundColor(.primary)
                                .frame(width: 36, height: 36)
                                .background(isHoveringPlay ? Color.primary.opacity(0.15) : Color.primary.opacity(0.08))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .onHover { isHoveringPlay = $0 }
                        .help(track.isPlaying ? "Pause" : "Play")
                        
                        Button(action: {
                            AppLogger.ui.debug("Tapped next track button")
                            playbackVM.nextTrack?()
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.body)
                                .foregroundColor(isHoveringNext ? .primary : .secondary)
                                .frame(width: 28, height: 28)
                                .background(isHoveringNext ? Color.primary.opacity(0.1) : Color.clear)
                                .clipShape(Circle())
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .onHover { isHoveringNext = $0 }
                        .help("Next Track")
                    }
                }
                
                // Progress Bar
                PlaybackProgressBar(track: track, playbackVM: playbackVM)
                
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.6))
                        .frame(width: 36, height: 36)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Nothing Playing")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Play a track to see lyrics.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 6)
            }
        }
        .padding(.vertical, 4)
    }
}
