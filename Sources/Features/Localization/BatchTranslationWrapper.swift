import SwiftUI
import NaturalLanguage
@preconcurrency import Translation

@available(macOS 15.0, *)
struct BatchTranslationWrapper<Item: TranslatableItem>: ViewModifier {
    let items: [Item]
    let isEnabled: Bool
    let sourceLanguage: String
    let targetLanguage: String
    let detectedLanguage: String?
    @Binding var translatedLines: [UUID: String]
    
    var config: TranslationSession.Configuration? {
        TranslationConfigurator.buildConfig(
            isEnabled: isEnabled,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            detectedLanguage: detectedLanguage
        )
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                Group {
                    if let config = config {
                        Color.clear
                            .translationTask(config) { session in
                                do {
                                    if config.source != nil {
                                        try await session.prepareTranslation()
                                    }
                                    var newTranslations: [UUID: String] = [:]
                                    for item in items {
                                        let response = try await session.translate(item.translatableText)
                                        let originalNormalized = item.translatableText.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
                                        let translatedNormalized = response.targetText.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
                                        
                                        if originalNormalized != translatedNormalized && !translatedNormalized.isEmpty {
                                            newTranslations[item.id] = response.targetText
                                        }
                                    }
                                    translatedLines = newTranslations
                                } catch {
                                    translatedLines = [:]
                                }
                            }
                            .id(items.map(\.id)) // Re-trigger task if items change
                    } else {
                        Color.clear.onAppear {
                            translatedLines = [:]
                        }
                    }
                }
            )
            .onChange(of: config) { _, newConfig in
                if newConfig == nil {
                    translatedLines = [:]
                }
            }
    }
}

extension View {
    @ViewBuilder
    func applyBatchTranslation<Item: TranslatableItem>(
        items: [Item],
        isEnabled: Bool,
        sourceLanguage: String,
        targetLanguage: String,
        detectedLanguage: String?,
        translatedLines: Binding<[UUID: String]>
    ) -> some View {
        if #available(macOS 15.0, *) {
            self.modifier(BatchTranslationWrapper(
                items: items,
                isEnabled: isEnabled,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                detectedLanguage: detectedLanguage,
                translatedLines: translatedLines
            ))
        } else {
            self
        }
    }
}
