import SwiftUI

public struct MarqueeText: View {
    public let text: String
    public let font: Font
    
    public init(text: String, font: Font) {
        self.text = text
        self.font = font
    }
    
    public var body: some View {
        ViewThatFits(in: .horizontal) {
            Text(text)
                .font(font)
                .lineLimit(1)
            
            ScrollingTextView(text: text, font: font)
        }
    }
}

struct ScrollingTextView: View {
    let text: String
    let font: Font
    
    @State private var textWidth: CGFloat = 0
    
    var body: some View {
        Text(text)
            .font(font)
            .lineLimit(1)
            .hidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                GeometryReader { containerGeo in
                    TimelineView(.animation) { timeline in
                        let diff = max(0, textWidth - containerGeo.size.width)
                        let offset = calculateOffset(time: timeline.date.timeIntervalSinceReferenceDate, diff: diff)
                        
                        Text(text)
                            .font(font)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .background(
                                GeometryReader { textGeo in
                                    Color.clear
                                        .onAppear { textWidth = textGeo.size.width }
                                        .onChange(of: text) { textWidth = textGeo.size.width }
                                }
                            )
                            .offset(x: -offset)
                    }
                }
                .clipped()
            )
    }
    
    private func calculateOffset(time: TimeInterval, diff: CGFloat) -> CGFloat {
        guard diff > 0 else { return 0 }
        
        let speed: CGFloat = 20.0 // points per second
        let duration = diff / speed
        let pauseDuration: TimeInterval = 2.0
        let totalCycle = (duration + pauseDuration) * 2 // back and forth
        
        let timeInCycle = time.truncatingRemainder(dividingBy: totalCycle)
        
        if timeInCycle < pauseDuration {
            return 0
        } else if timeInCycle < pauseDuration + duration {
            let progress = (timeInCycle - pauseDuration) / duration
            return diff * progress
        } else if timeInCycle < pauseDuration * 2 + duration {
            return diff
        } else {
            let progress = (timeInCycle - (pauseDuration * 2 + duration)) / duration
            return diff * (1 - progress)
        }
    }
}
