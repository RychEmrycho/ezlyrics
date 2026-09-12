import SwiftUI
@preconcurrency import Translation

struct LyricsOverlayView: View {
    @ObservedObject var syncEngine: SyncEngine
    @ObservedObject var settings = SettingsManager.shared
    
    @State private var translatedText: String?
    
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
                    
                    Text(active.text)
                        .font(.system(size: settings.fontSize, weight: .bold, design: fontDesign))
                        .foregroundColor(Color(hex: settings.textColorHex).opacity(0.3))
                        .multilineTextAlignment(textAlignment)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .overlay(
                            Text(active.text)
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
                
                if settings.enableTranslation, let translated = translatedText, !translated.isEmpty {
                    Text(translated)
                        .font(.system(size: max(10, settings.fontSize - 8), weight: .semibold, design: fontDesign))
                        .foregroundColor(Color(hex: settings.textColorHex).opacity(0.8))
                        .multilineTextAlignment(textAlignment)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
            } else {
                Text("•••")
                    .font(.system(size: settings.fontSize, weight: .bold, design: fontDesign))
                    .foregroundColor(Color(hex: settings.textColorHex).opacity(0.5))
            }
            
            if settings.lineLayout == "two" || settings.lineLayout == "three" {
                if let next = syncEngine.nextLine {
                    Text(next.text)
                        .font(.system(size: max(10, settings.fontSize - 6), weight: .medium, design: fontDesign))
                        .foregroundColor(Color(hex: settings.textColorHex).opacity(0.6))
                        .multilineTextAlignment(textAlignment)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                }
            }
            
            if settings.lineLayout == "three" {
                if let nextNext = syncEngine.nextNextLine {
                    Text(nextNext.text)
                        .font(.system(size: max(10, settings.fontSize - 12), weight: .regular, design: fontDesign))
                        .foregroundColor(Color(hex: settings.textColorHex).opacity(0.4))
                        .multilineTextAlignment(textAlignment)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Group {
                if settings.showBackground {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.black.opacity(settings.backgroundOpacity))
                }
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle()) // Make the transparent part clickable for dragging
        .applyTranslation(text: syncEngine.activeLine?.text ?? "", isEnabled: settings.enableTranslation, translatedText: $translatedText)
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
    @Binding var translatedText: String?
    @State private var config: TranslationSession.Configuration?
    
    func body(content: Content) -> some View {
        content
            .onChange(of: text) { newText in
                guard isEnabled, !newText.isEmpty, newText != "•••", newText != "♫", newText != "Lyrics are not synced" else {
                    translatedText = nil
                    return
                }
                // Invalidating the configuration triggers a new translation task
                config = TranslationSession.Configuration()
            }
            .translationTask(config) { session in
                if isEnabled {
                    do {
                        let response = try await session.translate(text)
                        translatedText = response.targetText
                    } catch {}
                }
            }
    }
}

extension View {
    @ViewBuilder
    func applyTranslation(text: String, isEnabled: Bool, translatedText: Binding<String?>) -> some View {
        if #available(macOS 15.0, *) {
            self.modifier(TranslationWrapper(text: text, isEnabled: isEnabled, translatedText: translatedText))
        } else {
            self.onChange(of: text) { _ in
                if isEnabled {
                    translatedText.wrappedValue = "(Requires macOS 15+)"
                } else {
                    translatedText.wrappedValue = nil
                }
            }
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
