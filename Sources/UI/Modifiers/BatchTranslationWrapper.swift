import SwiftUI
import NaturalLanguage
@preconcurrency import Translation

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
