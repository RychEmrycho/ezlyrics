import Foundation
import Translation

@available(macOS 15.0, *)
struct TranslationConfigurator {
    static func buildConfig(isEnabled: Bool, sourceLanguage: String, targetLanguage: String, detectedLanguage: String?) -> TranslationSession.Configuration? {
        guard isEnabled else { return nil }
        let target = Locale.Language(identifier: targetLanguage)
        
        if sourceLanguage == "auto" {
            if let domRawValue = detectedLanguage {
                if domRawValue.starts(with: targetLanguage.prefix(2)) {
                    return nil
                } else {
                    return TranslationSession.Configuration(
                        source: Locale.Language(identifier: domRawValue),
                        target: target
                    )
                }
            }
            return TranslationSession.Configuration(target: target)
        } else {
            return TranslationSession.Configuration(
                source: Locale.Language(identifier: sourceLanguage),
                target: target
            )
        }
    }
}
