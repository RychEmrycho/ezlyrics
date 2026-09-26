import SwiftUI

struct Wave: Shape {
    var baseStrength: Double
    var frequency: Double
    var phase: Double
    var progress: Double

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(phase, progress) }
        set {
            phase = newValue.first
            progress = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = Double(rect.width)
        let height = Double(rect.height)
        
        // As progress goes from 0 to 1, wave rises from 85% to 5% from the top
        let ratio = 0.85 - (0.80 * progress)
        let midHeight = height * ratio
        
        // Keep amplitude consistent so the horizontal speed doesn't visually increase
        let currentStrength = baseStrength
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 5) {
            let relativeX = x / frequency
            let sine = sin(relativeX + phase)
            let y = currentStrength * sine + midHeight
            
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

struct WavyBackgroundView: View {
    let track: Track
    @ObservedObject var playbackVM: PlaybackViewModel
    
    @State private var elapsed: TimeInterval
    
    init(track: Track, playbackVM: PlaybackViewModel) {
        self.track = track
        self.playbackVM = playbackVM
        _elapsed = State(initialValue: min(playbackVM.currentPlaybackTime(), track.duration))
    }
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var progress: Double {
        guard track.duration > 0 else { return 0 }
        return min(max(elapsed / track.duration, 0), 1)
    }
    
    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            // Speeds (radians per second): higher is faster
            let p1 = track.isPlaying ? time * 1.0 : 0
            let p2 = track.isPlaying ? time * 1.5 + 2.0 : 2
            let p3 = track.isPlaying ? time * 2.0 + 4.0 : 4
            
            ZStack {
                // Layer 1: Back wave (Slowest, tallest)
                Wave(baseStrength: 10, frequency: 70, phase: p1, progress: progress)
                    .fill(LinearGradient(colors: [.purple.opacity(0.15), .blue.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                // Layer 2: Middle wave
                Wave(baseStrength: 6, frequency: 50, phase: p2, progress: progress)
                    .fill(LinearGradient(colors: [.cyan.opacity(0.15), .blue.opacity(0.1)], startPoint: .bottomLeading, endPoint: .topTrailing))
                    
                // Layer 3: Front wave (Fastest, shortest)
                Wave(baseStrength: 3, frequency: 35, phase: p3, progress: progress)
                    .fill(LinearGradient(colors: [.accentColor.opacity(0.2), .accentColor.opacity(0.05)], startPoint: .leading, endPoint: .trailing))
            }
            .clipped()
        }
        .onReceive(timer) { _ in
            withAnimation(.linear(duration: 1.0)) {
                elapsed = min(playbackVM.currentPlaybackTime(), track.duration)
            }
        }
    }
}
