import SwiftUI

struct TranslationTab: View {
    @ObservedObject var settings: UserPreferences
    
    var body: some View {
        ScrollView {
            VStack {
                Form {
                    Section {
                        Toggle("Romanize Non-Latin Text", isOn: $settings.enableRomanization)
                        if settings.enableRomanization {
                            Picker("Display On", selection: $settings.romanizationDisplayMode) {
                                Text("Both").tag("both")
                                Text("Overlay Only").tag("overlayOnly")
                                Text("Full Lyrics Only").tag("fullLyricsOnly")
                            }
                        }
                        Toggle("Enable Translation", isOn: $settings.enableTranslation)
                        if settings.enableTranslation {
                            Picker("Display On", selection: $settings.translationDisplayMode) {
                                Text("Both").tag("both")
                                Text("Overlay Only").tag("overlayOnly")
                                Text("Full Lyrics Only").tag("fullLyricsOnly")
                            }
                        }
                    } header: {
                        Text("General")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                    }
                    
                    if settings.enableTranslation {
                        Divider()
                            .padding(.vertical, 8)
                        
                        Section {
                            Picker("From", selection: $settings.translationSource) {
                                Text("Auto-detect").tag("auto")
                                Divider()
                                Text("Japanese").tag("ja")
                                Text("Korean").tag("ko")
                                Text("Spanish").tag("es")
                                Text("French").tag("fr")
                                Text("Mandarin Chinese").tag("zh")
                                Text("Portuguese").tag("pt")
                                Text("German").tag("de")
                                Text("Italian").tag("it")
                                Text("Russian").tag("ru")
                            }
                            
                            Picker("To", selection: $settings.translationTarget) {
                                Text("English").tag("en")
                                Text("Japanese").tag("ja")
                                Text("Korean").tag("ko")
                                Text("Spanish").tag("es")
                                Text("French").tag("fr")
                                Text("Mandarin Chinese").tag("zh")
                            }
                        } header: {
                            Text("Languages")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 4)
                        }
                    }
                }
                Spacer()
            }
        }
        .padding()
    }
}
