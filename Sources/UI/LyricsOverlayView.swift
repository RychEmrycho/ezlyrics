import SwiftUI
import NaturalLanguage
@preconcurrency import Translation

struct LyricsOverlayView: View {
    @ObservedObject var syncEngine: SyncEngine
    @ObservedObject var settings = SettingsManager.shared
    
    @State private var translatedLines: [UUID: String] = [:]
    
    private var fallbackText: String {
        if let lyrics = syncEngine.currentLyrics {
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
            if let active = syncEngine.activeLine {
                TimelineView(.animation) { _ in
                    let effectiveTime = syncEngine.currentEffectiveTime()
                    
                    let isRomanized = settings.enableRomanization && settings.romanizationDisplayMode != "fullLyricsOnly" && Romanizer.romanize(active.text) != nil
                    let mainText = isRomanized ? Romanizer.romanize(active.text)! : active.text
                    let subText = isRomanized ? active.text : nil
                    
                    HStack(alignment: .center, spacing: 6) {
                        if isRomanized {
                            Image(systemName: "waveform")
                                .font(.system(size: max(10, settings.fontSize - 12), weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        KaraokeLyricLineView(
                            active: active,
                            effectiveTime: effectiveTime,
                            settings: settings,
                            fontDesign: fontDesign,
                            textAlignment: textAlignment,
                            displayText: mainText
                        )
                    }
                    
                    if let subText = subText {
                        Text(subText)
                            .font(.system(size: max(10, settings.fontSize - 6), weight: .medium, design: fontDesign))
                            .foregroundColor(Color(hex: settings.textColorHex).opacity(0.7))
                            .multilineTextAlignment(textAlignment)
                            .lineLimit(2)
                            .minimumScaleFactor(0.5)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    }
                }
                
                if settings.enableTranslation && settings.translationDisplayMode != "fullLyricsOnly", let translated = translatedLines[active.id], !translated.isEmpty {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Image(systemName: "translate")
                            .font(.system(size: max(8, settings.fontSize - 10), weight: .semibold))
                            .foregroundColor(Color(hex: settings.textColorHex).opacity(0.6))
                        
                        Text(translated)
                            .font(.system(size: max(10, settings.fontSize - 8), weight: .semibold, design: fontDesign))
                            .foregroundColor(Color(hex: settings.textColorHex).opacity(0.8))
                            .multilineTextAlignment(textAlignment)
                            .lineLimit(2)
                            .minimumScaleFactor(0.5)
                    }
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
            } else {
                Text(fallbackText)
                    .font(.system(size: settings.fontSize, weight: .bold, design: fontDesign))
                    .foregroundColor(Color(hex: settings.textColorHex).opacity(0.5))
            }
            
            if settings.lineLayout == "two" || settings.lineLayout == "three" {
                if let next = syncEngine.nextLine {
                    let isRomanized = settings.enableRomanization && settings.romanizationDisplayMode != "fullLyricsOnly" && Romanizer.romanize(next.text) != nil
                    let textToShow = isRomanized ? Romanizer.romanize(next.text)! : next.text
                    
                    HStack(alignment: .center, spacing: 6) {
                        if isRomanized {
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
            
            if settings.lineLayout == "three" {
                if let nextNext = syncEngine.nextNextLine {
                    let isRomanized = settings.enableRomanization && settings.romanizationDisplayMode != "fullLyricsOnly" && Romanizer.romanize(nextNext.text) != nil
                    let textToShow = isRomanized ? Romanizer.romanize(nextNext.text)! : nextNext.text
                    
                    HStack(alignment: .center, spacing: 6) {
                        if isRomanized {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle()) // Make the transparent part clickable for dragging
        .applyBatchTranslation(lines: syncEngine.currentLyrics?.lines ?? [], detectedLanguage: syncEngine.currentLyrics?.detectedLanguage, isEnabled: settings.enableTranslation && settings.translationDisplayMode != "fullLyricsOnly", sourceLanguage: settings.translationSource, targetLanguage: settings.translationTarget, translatedLines: $translatedLines)
    }
    
}

struct KaraokeLyricLineView: View {
    let active: LyricLine
    let effectiveTime: TimeInterval
    @ObservedObject var settings: SettingsManager
    let fontDesign: Font.Design
    let textAlignment: TextAlignment
    let displayText: String
    
    var body: some View {
        Text(displayText)
            .font(.system(size: settings.fontSize, weight: .bold, design: fontDesign))
            .foregroundColor(Color(hex: settings.textColorHex).opacity(0.3))
            .multilineTextAlignment(textAlignment)
            .lineLimit(2)
            .minimumScaleFactor(0.5)
            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            .overlay(
                Text(displayText)
                    .font(.system(size: settings.fontSize, weight: .bold, design: fontDesign))
                    .foregroundColor(Color(hex: settings.textColorHex))
                    .multilineTextAlignment(textAlignment)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    .mask(alignment: .leading) {
                        GeometryReader { geo in
                            Rectangle()
                                .frame(width: geo.size.width * fillRatio(for: active, at: effectiveTime))
                        }
                    }
            )
    }
    
    private func fillRatio(for line: LyricLine, at time: TimeInterval) -> CGFloat {
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

@available(macOS 15.0, *)
struct TranslationWrapper: ViewModifier {
    let text: String
    let isEnabled: Bool
    let sourceLanguage: String
    let targetLanguage: String
    @Binding var translatedText: String?
    @State private var config: TranslationSession.Configuration?
    
    func body(content: Content) -> some View {
        content
            .onChange(of: text) { _, newText in
                guard isEnabled, !newText.isEmpty, newText != "•••", newText != "♫", newText != "Lyrics are not synced" else {
                    translatedText = nil
                    return
                }
                let target = Locale.Language(identifier: targetLanguage)
                if config == nil {
                    if sourceLanguage == "auto" {
                        let recognizer = NLLanguageRecognizer()
                        recognizer.processString(newText)
                        if let dom = recognizer.dominantLanguage, dom.rawValue.starts(with: targetLanguage.prefix(2)) {
                            config = nil
                        } else {
                            config = TranslationSession.Configuration(target: target)
                        }
                    } else {
                        let source = Locale.Language(identifier: sourceLanguage)
                        config = TranslationSession.Configuration(source: source, target: target)
                    }
                } else {
                    // Check if we need to invalidate config because language changed
                    if sourceLanguage == "auto" {
                        let recognizer = NLLanguageRecognizer()
                        recognizer.processString(newText)
                        if let dom = recognizer.dominantLanguage, dom.rawValue.starts(with: targetLanguage.prefix(2)) {
                            config = nil
                            translatedText = nil
                            return
                        }
                    }
                }
            }
            .onChange(of: sourceLanguage) { _, _ in
                config = nil
                translatedText = nil
            }
            .onChange(of: targetLanguage) { _, _ in
                config = nil
                translatedText = nil
            }
            .onChange(of: isEnabled) { _, enabled in
                if !enabled {
                    config = nil
                    translatedText = nil
                }
            }
            .background(
                Group {
                    if let config = config {
                        Color.clear
                            .translationTask(config) { session in
                                guard isEnabled else { return }
                                do {
                                    if sourceLanguage != "auto" {
                                        try await session.prepareTranslation()
                                    }
                                    let response = try await session.translate(text)
                                    translatedText = response.targetText
                                } catch {
                                    translatedText = nil
                                }
                            }
                    }
                }
            )
    }
}

extension View {
    @ViewBuilder
    func applyTranslation(text: String, isEnabled: Bool, sourceLanguage: String, targetLanguage: String, translatedText: Binding<String?>) -> some View {
        if #available(macOS 15.0, *) {
            self.modifier(TranslationWrapper(text: text, isEnabled: isEnabled, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage, translatedText: translatedText))
        } else {
            self.onChange(of: text) { _, _ in
                translatedText.wrappedValue = isEnabled ? "(Requires macOS 15+)" : nil
            }
        }
    }
}

@available(macOS 15.0, *)
struct BatchTranslationWrapper: ViewModifier {
    let lines: [LyricLine]
    let detectedLanguage: String?
    let isEnabled: Bool
    let sourceLanguage: String
    let targetLanguage: String
    @Binding var translatedLines: [UUID: String]
    @State private var config: TranslationSession.Configuration?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if isEnabled && !lines.isEmpty { triggerTranslation() }
            }
            .onChange(of: isEnabled) { _, enabled in
                if enabled { triggerTranslation() } else { translatedLines = [:]; config = nil }
            }
            .onChange(of: sourceLanguage) { _, _ in triggerTranslation() }
            .onChange(of: targetLanguage) { _, _ in triggerTranslation() }
            .onChange(of: lines.first?.id) { _, _ in triggerTranslation() }
            .background(
                Group {
                    if let config = config {
                        Color.clear
                            .translationTask(config) { session in
                                do {
                                    if sourceLanguage != "auto" {
                                        try await session.prepareTranslation()
                                    }
                                    translatedLines = [:]
                                    for line in lines where !line.text.isEmpty && line.text != "•••" && line.text != "♫" {
                                        let response = try await session.translate(line.text)
                                        translatedLines[line.id] = response.targetText
                                    }
                                } catch {
                                    translatedLines = [:]
                                }
                            }
                    }
                }
            )
    }
    
    private func triggerTranslation() {
        guard isEnabled else { return }
        let target = Locale.Language(identifier: targetLanguage)
        if sourceLanguage == "auto" {
            if let domRawValue = detectedLanguage {
                if domRawValue.starts(with: targetLanguage.prefix(2)) {
                    config = nil
                    translatedLines = [:]
                    return
                } else {
                    config = TranslationSession.Configuration(
                        source: Locale.Language(identifier: domRawValue),
                        target: target
                    )
                    return
                }
            }
            config = TranslationSession.Configuration(target: target)
        } else {
            config = TranslationSession.Configuration(
                source: Locale.Language(identifier: sourceLanguage),
                target: target
            )
        }
    }
}

extension View {
    @ViewBuilder
    func applyBatchTranslation(lines: [LyricLine], detectedLanguage: String?, isEnabled: Bool, sourceLanguage: String, targetLanguage: String, translatedLines: Binding<[UUID: String]>) -> some View {
        if #available(macOS 15.0, *) {
            self.modifier(BatchTranslationWrapper(lines: lines, detectedLanguage: detectedLanguage, isEnabled: isEnabled, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage, translatedLines: translatedLines))
        } else {
            self
        }
    }
}

// Helper for Hex colors
extension Color {
    init(hex: String) {
        var cleanHexCode = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanHexCode = cleanHexCode.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: cleanHexCode).scanHexInt64(&rgb)
        let redValue = Double((rgb >> 16) & 0xFF) / 255.0
        let greenValue = Double((rgb >> 8) & 0xFF) / 255.0
        let blueValue = Double(rgb & 0xFF) / 255.0
        self.init(red: redValue, green: greenValue, blue: blueValue)
    }
}
