import SwiftUI

struct SearchResultRow: View {
    let result: LyricSearchResult
    let isApplied: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(result.artistName) - \(result.trackName)")
                        .font(.body)
                        .foregroundColor(isApplied ? .accentColor : .primary)
                    HStack(spacing: 4) {
                        Text("Duration: \(Int(result.duration ?? 0))s •")
                        if result.hasSyncedLyrics {
                            Text("Synced")
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        } else if result.hasPlainLyrics {
                            Text("Plain")
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.yellow.opacity(0.2))
                                .cornerRadius(4)
                        }
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
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
            .background(isHovered ? (isApplied ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.2)) : Color.clear)
            .cornerRadius(4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
