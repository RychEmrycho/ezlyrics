import SwiftUI
import NaturalLanguage
@preconcurrency import Translation

struct LyricsOverlayView: View {
    @ObservedObject var playbackVM: PlaybackViewModel
    @ObservedObject var settings = UserPreferences.shared
    
    @State private var translatedLines: [UUID: String] = [:]
    
    private var fallbackText: String {
        if let lyrics = playbackVM.currentLyrics {
            if lyrics.lines.isEmpty {
                return "No lyrics found"
            } else if !lyrics.isSynced {
                return "Lyrics not synced"
            }
        }
        return "•••"
    }
    
    private var fontDesign: Font.Design {
        switch settings.typography {
        case "system": return .default
        case "monospaced": return .monospaced
        case "serif": return .serif
        default: return .rounded
        }
    }
    
    private var textAlignment: TextAlignment {
        switch settings.alignment {
        case "left": return .leading
        case "right": return .trailing
        default: return .center
        }
    }
    
    private var stackAlignment: HorizontalAlignment {
        switch settings.alignment {
        case "left": return .leading
        case "right": return .trailing
        default: return .center
        }
    }
    
    var body: some View {
        VStack(alignment: stackAlignment, spacing: 8) {
            if let active = playbackVM.activeLine {
                TimelineView(.animation) { context in
                    let effectiveTime = playbackVM.currentPlaybackTime()
                    
                    let isRomanized = settings.enableRomanization && settings.romanizationDisplayMode != "fullLyricsOnly" && Romanizer().romanize(active.text) != nil
                    let mainText = isRomanized ? Romanizer().romanize(active.text)! : active.text
                    let subText = isRomanized ? active.text : nil
                    let translated = settings.enableTranslation && settings.translationDisplayMode != "fullLyricsOnly" ? translatedLines[active.id] : nil
                    
                    VStack(alignment: stackAlignment, spacing: 8) {
                        HStack(alignment: .center, spacing: 6) {
                            if isRomanized {
                                Image(systemName: "waveform")
                                    .font(.system(size: max(10, settings.fontSize - 12), weight: .bold))
                                    .foregroundColor(.white)
                            }
                            let isLongEnough = active.text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 8
                            if settings.funModeBouncingSinger && isLongEnough {
                                BouncingSinger(isReversed: true)
                            }
                            
                            FloatingLyricLineView(
                                line: active,
                                effectiveTime: effectiveTime,
                                settings: settings,
                                fontDesign: fontDesign,
                                textAlignment: textAlignment,
                                displayText: mainText
                            )
                            
                            if settings.funModeBouncingSinger && isLongEnough {
                                BouncingSinger(isReversed: false)
                            }
                        }
                        
                        if let subText = subText {
                            FloatingLyricLineView(
                                line: active,
                                effectiveTime: effectiveTime,
                                settings: settings,
                                fontDesign: fontDesign,
                                textAlignment: textAlignment,
                                displayText: subText,
                                fontSize: max(10, settings.fontSize - 6),
                                fontWeight: .medium,
                                isMainText: false
                            )
                        }
                        
                        if let translated = translated, !translated.isEmpty {
                            HStack(alignment: .center, spacing: 6) {
                                Image(systemName: "translate")
                                    .font(.system(size: max(8, settings.fontSize - 10), weight: .semibold))
                                    .foregroundColor(Color(hex: settings.textColorHex).opacity(0.8))
                                
                                FloatingLyricLineView(
                                    line: active,
                                    effectiveTime: effectiveTime,
                                    settings: settings,
                                    fontDesign: fontDesign,
                                    textAlignment: textAlignment,
                                    displayText: translated,
                                    fontSize: max(10, settings.fontSize - 8),
                                    fontWeight: .semibold,
                                    isMainText: false
                                )
                            }
                        }
                    }
                    .id(active.id)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 8)),
                        removal: .opacity.combined(with: .offset(y: -8))
                    ))
                }
                .animation(.easeOut(duration: 0.15), value: active.id)
            } else {
                Text(fallbackText)
                    .font(.system(size: settings.fontSize, weight: .bold, design: fontDesign))
                    .foregroundColor(Color(hex: settings.textColorHex).opacity(0.5))
            }
            
            if let active = playbackVM.activeLine {
                let isRomanized = settings.enableRomanization && settings.romanizationDisplayMode != "fullLyricsOnly" && Romanizer().romanize(active.text) != nil
                let isTranslated = settings.enableTranslation && settings.translationDisplayMode != "fullLyricsOnly" && translatedLines[active.id] != nil && !translatedLines[active.id]!.isEmpty
                
                let maxRows: Int = {
                    switch settings.lineLayout {
                    case "single": return 1
                    case "two": return 2
                    case "three": return 3
                    default: return 1
                    }
                }()
                
                let activeRows = 1 + (isRomanized ? 1 : 0) + (isTranslated ? 1 : 0)
                let availableRows = maxRows - activeRows
                
                if availableRows >= 1 {
                    if let next = playbackVM.nextLine {
                        let isRomanizedNext = settings.enableRomanization && settings.romanizationDisplayMode != "fullLyricsOnly" && Romanizer().romanize(next.text) != nil
                        let textToShow = isRomanizedNext ? Romanizer().romanize(next.text)! : next.text
                        
                        HStack(alignment: .center, spacing: 6) {
                            if isRomanizedNext {
                                Image(systemName: "waveform")
                                    .font(.system(size: max(8, settings.fontSize - 14), weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            FloatingLyricLineView(
                                line: next,
                                effectiveTime: playbackVM.currentPlaybackTime(),
                                settings: settings,
                                fontDesign: fontDesign,
                                textAlignment: textAlignment,
                                displayText: textToShow,
                                fontSize: max(10, settings.fontSize - 6),
                                fontWeight: .medium,
                                isMainText: false
                            )
                        }
                    }
                }
                
                if availableRows >= 2 {
                    if let nextNext = playbackVM.nextNextLine {
                        let isRomanizedNextNext = settings.enableRomanization && settings.romanizationDisplayMode != "fullLyricsOnly" && Romanizer().romanize(nextNext.text) != nil
                        let textToShow = isRomanizedNextNext ? Romanizer().romanize(nextNext.text)! : nextNext.text
                        
                        HStack(alignment: .center, spacing: 6) {
                            if isRomanizedNextNext {
                                Image(systemName: "waveform")
                                    .font(.system(size: max(8, settings.fontSize - 14), weight: .regular))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            FloatingLyricLineView(
                                line: nextNext,
                                effectiveTime: playbackVM.currentPlaybackTime(),
                                settings: settings,
                                fontDesign: fontDesign,
                                textAlignment: textAlignment,
                                displayText: textToShow,
                                fontSize: max(10, settings.fontSize - 12),
                                fontWeight: .regular,
                                isMainText: false
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Group {
                if settings.showBackground {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: settings.backgroundColorHex).opacity(settings.backgroundOpacity))
                }
            }
        )
        .overlay(alignment: .bottomLeading) {
            if settings.funModeNyanCat {
                NyanCatOverlay(playbackVM: playbackVM)
            }
        }
        .overlay {
            if settings.funModeConfetti, let active = playbackVM.activeLine, active.text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 8 {
                HStack {
                    ConfettiExplosion(trigger: playbackVM.activeLine?.id ?? UUID())
                    Spacer()
                    ConfettiExplosion(trigger: playbackVM.activeLine?.id ?? UUID())
                    Spacer()
                    ConfettiExplosion(trigger: playbackVM.activeLine?.id ?? UUID())
                }
                .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay {
            if settings.funModeFloatingNotes, let track = playbackVM.currentTrack {
                FloatingNotesView(isPlaying: track.isPlaying)
            }
        }
        .contentShape(Rectangle()) // Make the transparent part clickable for dragging
        .applyBatchTranslation(
            items: (playbackVM.currentLyrics?.lines ?? []).filter(\.isTranslatable),
            isEnabled: settings.enableTranslation && settings.translationDisplayMode != "fullLyricsOnly",
            sourceLanguage: settings.translationSource,
            targetLanguage: settings.translationTarget,
            detectedLanguage: playbackVM.currentLyrics?.detectedLanguage,
            translatedLines: $translatedLines
        )
    }
}

struct BouncingSinger: View {
    var isReversed: Bool = false
    @State private var offset: CGFloat = 0
    let emojis = ["🎤", "🎵", "🕺", "💃", "✨"]
    @State private var emoji: String = "🎤"
    
    var body: some View {
        Text(emoji)
            .font(.system(size: 24))
            .scaleEffect(x: isReversed ? -1 : 1, y: 1)
            .offset(y: offset)
            .onAppear {
                emoji = emojis.randomElement() ?? "🎤"
                withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                    offset = -12
                }
            }
    }
}

struct FloatingNotesView: View {
    let isPlaying: Bool
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05, paused: !isPlaying)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                ForEach(0..<6) { i in
                    let speed = 40.0 + Double(i) * 15.0
                    let flyHeight = 150.0
                    let yOffset = (time * speed + Double(i) * 120).truncatingRemainder(dividingBy: flyHeight + 50)
                    let xOffset = sin(time * 1.5 + Double(i)) * 40 + geo.size.width * (0.15 + Double(i) * 0.14)
                    
                    Text(i % 2 == 0 ? "🎵" : (i % 3 == 0 ? "✨" : "🎶"))
                        .font(.system(size: 16))
                        .opacity(1.0 - (yOffset / flyHeight))
                        .position(x: xOffset, y: flyHeight - yOffset - 20)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct ConfettiExplosion: View {
    let trigger: AnyHashable
    
    var body: some View {
        ConfettiBurst()
            .id(trigger)
    }
}

struct ConfettiBurst: View {
    @State private var explode = false
    
    let particles: [(color: Color, distance: Double, duration: Double)] = (0..<24).map { _ in
        (
            color: [Color.red, .blue, .green, .yellow, .pink, .purple, .orange, .cyan].randomElement()!,
            distance: Double.random(in: 40...120),
            duration: Double.random(in: 0.4...0.8)
        )
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<24, id: \.self) { i in
                let p = particles[i]
                Circle()
                    .fill(p.color)
                    .frame(width: 6, height: 6)
                    .offset(y: explode ? -p.distance : 0)
                    .rotationEffect(.degrees(Double(i) * 15))
                    .opacity(explode ? 0 : 1)
                    .animation(.easeOut(duration: p.duration), value: explode)
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                explode = true
            }
        }
    }
}

struct NyanCatOverlay: View {
    @ObservedObject var playbackVM: PlaybackViewModel

    var body: some View {
        if let active = playbackVM.activeLine {
            let isActiveLong = active.text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 8
            let isNextLong = (playbackVM.nextLine?.text.trimmingCharacters(in: .whitespacesAndNewlines).count ?? 0) >= 8
            let isSynced = playbackVM.currentLyrics?.isSynced ?? true
            let hasSyllables = active.syllables?.isEmpty == false
            let canTrackKaraoke = isActiveLong && isSynced && hasSyllables

            if isActiveLong || isNextLong {
                GeometryReader { geo in
                    TimelineView(.animation) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                        let maxW = geo.size.width
                        let catTravel = max(0, maxW - 48) // pixels the cat can travel

                        // Ping-pong: 12s right (ratio 0→1), 12s left (ratio 1→0)
                        let cycle = t.truncatingRemainder(dividingBy: 16.0)
                        let isFlyingLeft = !canTrackKaraoke && cycle >= 8.0
                        let ratio: CGFloat = {
                            if canTrackKaraoke {
                                return FloatingLyricLineView.fillRatio(
                                    for: active, at: playbackVM.currentPlaybackTime())
                            } else {
                                return cycle >= 8.0
                                    ? CGFloat((16.0 - cycle) / 8.0)
                                    : CGFloat(cycle / 8.0)
                            }
                        }()

                        let bounce = sin(t * 6.0) * 0.5

                        // ── Cat position (left edge of 48px sprite) ──
                        let catX = catTravel * ratio

                        // ── ACTIVE TAIL: grows behind the cat from 0 ──
                        // Flying RIGHT: tail on LEFT,  width = catX (grows as ratio ↑)
                        // Flying LEFT:  tail on RIGHT, width = catTravel*(1-ratio) (grows as ratio ↓)
                        // +10 overlap so tail tucks into the cat body (no gap)
                        let activeW: CGFloat = isFlyingLeft && !canTrackKaraoke
                            ? catTravel * (1.0 - ratio) + 10
                            : catX + 10
                        let activeX: CGFloat = isFlyingLeft && !canTrackKaraoke
                            ? catX + 38   // 48 - 10 overlap
                            : 0

                        // ── OLD TAIL: slides off in front after turnaround ──
                        let timeInPhase = isFlyingLeft ? (cycle - 8.0) : cycle
                        let slideDuration = 3.0
                        let slideProgress = min(1.0, timeInPhase / slideDuration)
                        let showOldTail = !canTrackKaraoke && slideProgress < 1.0

                        ZStack(alignment: .topLeading) {
                            // Tails layer — clipped horizontally to overlay width
                            ZStack(alignment: .topLeading) {
                                // Old tail sliding away in front of cat
                                if showOldTail {
                                    let slideX: CGFloat = isFlyingLeft
                                        ? -maxW * slideProgress
                                        : maxW * slideProgress
                                    rainbowTail(width: maxW, time: t)
                                        .offset(x: slideX, y: 11 + bounce)
                                }

                                // Active tail growing behind cat
                                if activeW > 1 {
                                    rainbowTail(width: activeW, time: t)
                                        .offset(x: activeX, y: 11 + bounce)
                                }
                            }
                            .frame(width: maxW, height: 34, alignment: .topLeading)
                            .clipped()

                            // Cat sprite (outside clipped area so it can overflow vertically)
                            NyanCatImage.image
                                .resizable()
                                .interpolation(.none)
                                .antialiased(false)
                                .scaledToFit()
                                .frame(width: 48, height: 34)
                                .scaleEffect(x: isFlyingLeft ? -1 : 1)
                                .rotationEffect(.degrees(sin(t * 15.0) * 5.0))
                                .offset(x: catX, y: bounce)
                        }
                        .offset(y: 17)
                        .id(canTrackKaraoke ? active.id : AnyHashable("bounce"))
                        .transition(.asymmetric(
                            insertion: .identity,
                            removal: .move(edge: .trailing)
                        ))
                        .animation(.easeOut(duration: 1.5),
                                   value: canTrackKaraoke ? active.id : AnyHashable("bounce"))
                    }
                }
                .frame(height: 34)
            }
        }
    }

    /// Rainbow tail: wavy gradient chunks with simple consistent wave.
    @ViewBuilder
    private func rainbowTail(width: CGFloat, time: TimeInterval) -> some View {
        let chunkSize: CGFloat = 10.0
        let chunks = Int(ceil(width / chunkSize))

        HStack(spacing: 0) {
            ForEach(0..<max(0, chunks), id: \.self) { i in
                let w = (i == chunks - 1)
                    ? (width - CGFloat(i) * chunkSize)
                    : chunkSize
                // Pixelated wobble: each chunk wobbles independently
                let frame = Int(time / 0.4)
                let hash = (i &* 2654435761 &+ frame &* 2246822519)
                let yOff: CGFloat = (hash % 3 == 0) ? -1.0 : (hash % 3 == 1) ? 1.0 : 0.0

                LinearGradient(
                    colors: [.red, .orange, .yellow, .green, .blue, .purple],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(width: max(0, w), height: 12)
                .offset(y: yOff)
            }
        }
        .frame(width: max(0, width), alignment: .leading)
    }
}
