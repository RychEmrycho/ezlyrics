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
                        .foregroundColor(isApplied ? .accentColor : .primary)
                    HStack(spacing: 4) {
                        if result.syncedLyrics != nil {
                            Text("♫")
                                .foregroundColor(.green)
                            Text("Synced •")
                        } else {
                            Image(systemName: "text.alignleft")
                                .foregroundColor(.yellow)
                            Text("Plain •")
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
                        .foregroundColor(.accentColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isHovered ? (isApplied ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.06)) : (isApplied ? Color.accentColor.opacity(0.05) : Color.clear))
            .cornerRadius(6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
