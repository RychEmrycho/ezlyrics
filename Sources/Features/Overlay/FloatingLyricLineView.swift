import SwiftUI

struct FloatingLyricLineView: View {
    let line: LyricLine
    let effectiveTime: TimeInterval
    @ObservedObject var settings: UserPreferences
    let fontDesign: Font.Design
    let textAlignment: TextAlignment
    let displayText: String
    var fontSize: CGFloat? = nil
    var fontWeight: Font.Weight = .bold
    var isMainText: Bool = true
    
    private var styledText: some View {
        Group {
            if settings.funModeWobblySinger {
                WobblyText(
                    text: displayText,
                    fontDesign: fontDesign,
                    fontSize: fontSize ?? settings.fontSize,
                    fontWeight: fontWeight
                )
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            } else {
                Text(displayText)
                    .font(.system(size: fontSize ?? settings.fontSize, weight: fontWeight, design: fontDesign))
                    .multilineTextAlignment(textAlignment)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
        }
    }
    
    var body: some View {
        styledText
            .foregroundColor(Color(hex: settings.textColorHex).opacity(0.3))
            .overlay(
                Group {
                    if settings.funModeDiscoGradient {
                        DiscoGradient()
                            .mask(styledText)
                    } else {
                        styledText
                            .foregroundColor(Color(hex: settings.textColorHex))
                    }
                }
                .mask(alignment: .leading) {
                    GeometryReader { geo in
                        Rectangle()
                            .frame(width: geo.size.width * Self.fillRatio(for: line, at: effectiveTime))
                    }
                }
            )
            .overlay(alignment: .bottomLeading) {
                // Nyan cat moved to LyricsOverlayView bottom edge
            }
    }
    
    static func fillRatio(for line: LyricLine, at time: TimeInterval) -> CGFloat {
        guard let syllables = line.syllables, !syllables.isEmpty else {
            return time >= line.timestamp ? 1.0 : 0.0
        }
        
        let totalSyllables = CGFloat(syllables.count)
        
        for (index, syllable) in syllables.enumerated() {
            let nextTimestamp = (index + 1 < syllables.count) ? syllables[index + 1].timestamp : line.timestamp + 5.0
            if time >= syllable.timestamp && time < nextTimestamp {
                let duration = nextTimestamp - syllable.timestamp
                let elapsed = time - syllable.timestamp
                let progress = CGFloat(elapsed / duration)
                
                let ratio = (CGFloat(index) + progress) / totalSyllables
                return min(max(ratio, 0.0), 1.0)
            } else if time < syllable.timestamp {
                if index == 0 { return 0.0 }
                return CGFloat(index) / totalSyllables
            }
        }
        
        return 1.0
    }
}

struct DiscoGradient: View {
    @State private var phase: Double = 0
    var body: some View {
        LinearGradient(
            colors: [.red, .orange, .yellow, .green, .blue, .purple, .pink, .red],
            startPoint: .leading,
            endPoint: .trailing
        )
        .hueRotation(.degrees(phase))
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase = 360
            }
        }
    }
}

struct WobblyText: View {
    let text: String
    let fontDesign: Font.Design
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    
    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 0) {
                ForEach(Array(text.enumerated()), id: \.offset) { index, char in
                    Text(String(char))
                        .font(.system(size: fontSize, weight: fontWeight, design: fontDesign))
                        .offset(y: sin(time * 4.0 + Double(index) * 0.4) * (char.isWhitespace ? 0 : 3))
                }
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.2)
    }
}
