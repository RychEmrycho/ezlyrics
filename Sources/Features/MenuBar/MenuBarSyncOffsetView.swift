import SwiftUI

struct MenuBarSyncOffsetView: View {
    @ObservedObject var playbackVM: PlaybackViewModel
    @State private var offsetInput: String = "0"
    
    var body: some View {
        HStack {
            Text("Lyrics Sync")
                .font(.headline)
                .foregroundColor(.secondary)
                .help("Adjust timing if lyrics are out of sync with the audio")
            
            Spacer()
            
            if playbackVM.userOffset != 0 {
                Button(action: { 
                    playbackVM.userOffset = 0 
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .opacity))
                .padding(.trailing, 4)
            }
            
            HStack(spacing: 0) {
                Button(action: { adjustOffset(by: -0.1) }) {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 24, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Divider()
                    .frame(height: 12)
                
                HStack(spacing: 2) {
                    TextField("0", text: $offsetInput)
                        .textFieldStyle(.plain)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.primary)
                        .frame(width: 36)
                        .multilineTextAlignment(.trailing)
                        .onSubmit {
                            applyOffset()
                        }
                    Text("ms")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.trailing, 4)
                }
                .frame(width: 56)
                
                Divider()
                    .frame(height: 12)
                
                Button(action: { adjustOffset(by: 0.1) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 24, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            
        }
        .padding(.vertical, 4)
        .animation(.snappy, value: playbackVM.userOffset)
        .onAppear {
            updateOffsetText(from: playbackVM.userOffset)
        }
        .onChange(of: playbackVM.userOffset) { _, newValue in
            updateOffsetText(from: newValue)
        }
    }
    
    private func adjustOffset(by step: Double) {
        playbackVM.userOffset += step
    }
    
    private func applyOffset() {
        let clean = offsetInput.trimmingCharacters(in: .whitespaces)
        let raw = Double(clean) ?? 0
        let val = raw / 1000.0
        
        if playbackVM.userOffset != val {
            playbackVM.userOffset = val
        }
    }

    private func updateOffsetText(from val: Double) {
        let ms = Int(round(val * 1000))
        offsetInput = "\(ms)"
    }
}
