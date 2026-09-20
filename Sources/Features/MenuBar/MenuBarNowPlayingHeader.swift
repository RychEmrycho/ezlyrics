import SwiftUI

struct MenuBarNowPlayingHeader: View {
    let track: Track?
    
    var body: some View {
        VStack(spacing: 4) {
            if let track = track {
                Text("Now Playing")
                    .font(.headline)
                    .fontWeight(.semibold)
                MarqueeText(text: track.title, font: .headline)
                
                HStack(spacing: 4) {
                    MarqueeText(text: track.artist, font: .subheadline)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                        .imageScale(.small)
                    Text("\(Int(track.duration))s")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Nothing playing")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
