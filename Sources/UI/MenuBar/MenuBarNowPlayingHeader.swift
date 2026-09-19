import SwiftUI

struct MenuBarNowPlayingHeader: View {
    let track: NowPlayingTrack?
    
    var body: some View {
        VStack {
            Text("Now Playing")
                .font(.headline)
            if let track = track {
                Text("\(track.artist) - \(track.title) (\(Int(track.duration))s)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Nothing playing")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
