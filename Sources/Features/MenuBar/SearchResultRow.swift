import SwiftUI

struct SearchResultRow: View {
    let result: SearchResult
    let isApplied: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(result.artistName) - \(result.trackName)")
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.primary)
                    HStack(spacing: 4) {
                        if result.syncedLyrics != nil {
                            HStack(spacing: 2) {
                                Image(systemName: "music.note")
                                Text("Synced")
                            }
                            .pillBadge(color: Color.primary.opacity(0.1), textColor: .primary)
                            .help("Synced lyrics available")
                        } else {
                            HStack(spacing: 2) {
                                Image(systemName: "text.alignleft")
                                Text("Plain")
                            }
                            .pillBadge(color: Color.primary.opacity(0.1), textColor: .primary)
                            .help("Plain lyrics only")
                        }
                        Image(systemName: "clock")
                        Text(formatTime(result.duration ?? 0))
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                Spacer()
                if isApplied {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isApplied ? Color.primary.opacity(0.12) : (isHovered ? Color.primary.opacity(0.06) : Color.clear))
            .cornerRadius(6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(isApplied ? "Currently applied lyrics" : "Apply these lyrics")
        .onHover { hovering in
            isHovered = hovering
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
