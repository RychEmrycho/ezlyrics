import SwiftUI

struct MenuBarSyncOffsetView: View {
    @ObservedObject var playbackVM: PlaybackViewModel
    @State private var offsetInput: String = "0"
    
    var body: some View {
        HStack {
            Text("Sync Offset:")
                .font(.headline)
            Spacer()
            
            Button(action: { adjustOffset(by: -0.1) }) {
                Image(systemName: "minus.square")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            
            TextField("Offset", text: $offsetInput)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
                .multilineTextAlignment(.trailing)
                .onSubmit {
                    applyOffset()
                }
            
            Button(action: { adjustOffset(by: 0.1) }) {
                Image(systemName: "plus.square")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            
            Text("ms")
                .foregroundColor(.secondary)
                .font(.subheadline)
            
            Button(action: { playbackVM.userOffset = 0 }) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
            }
            .buttonStyle(.plain)
            .padding(.leading, 4)
        }
        .padding(.vertical, 4)
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
