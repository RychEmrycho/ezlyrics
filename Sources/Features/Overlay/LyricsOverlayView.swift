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
                            
                            FloatingLyricLineView(
                                line: active,
                                effectiveTime: effectiveTime,
                                settings: settings,
                                fontDesign: fontDesign,
                                textAlignment: textAlignment,
                                displayText: mainText
                            )
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
                                fontWeight: .medium
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
                                    fontWeight: .semibold
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
                            
                            Text(textToShow)
                                .font(.system(size: max(10, settings.fontSize - 6), weight: .medium, design: fontDesign))
                                .foregroundColor(Color(hex: settings.textColorHex).opacity(0.6))
                                .multilineTextAlignment(textAlignment)
                                .lineLimit(2)
                                .minimumScaleFactor(0.5)
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
                            
                            Text(textToShow)
                                .font(.system(size: max(10, settings.fontSize - 12), weight: .regular, design: fontDesign))
                                .foregroundColor(Color(hex: settings.textColorHex).opacity(0.4))
                                .multilineTextAlignment(textAlignment)
                                .lineLimit(2)
                                .minimumScaleFactor(0.5)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
