import SwiftUI

struct TranslationTab: View {
    @ObservedObject var settings: UserPreferences
    
    var body: some View {
        Form {
            Section("General") {
                Toggle(isOn: $settings.enableRomanization) {
                    Label("Romanize Non-Latin Text", systemImage: "waveform")
                }
                
                if settings.enableRomanization {
                    Picker(selection: $settings.romanizationDisplayMode) {
                        Text("Both").tag("both")
                        Text("Overlay Only").tag("overlayOnly")
                        Text("Full Lyrics Only").tag("fullLyricsOnly")
                    } label: {
                        Label("Display On", systemImage: "display")
                    }
                }
                
                Toggle(isOn: $settings.enableTranslation) {
                    Label("Enable Translation", systemImage: "translate")
                }
                
                if settings.enableTranslation {
                    Picker(selection: $settings.translationDisplayMode) {
                        Text("Both").tag("both")
                        Text("Overlay Only").tag("overlayOnly")
                        Text("Full Lyrics Only").tag("fullLyricsOnly")
                    } label: {
                        Label("Display On", systemImage: "display")
                    }
                }
            }
            
            if settings.enableTranslation {
                Section("Languages") {
                    Picker(selection: $settings.translationSource) {
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
                    } label: {
                        Label("From", systemImage: "globe")
                    }
                    
                    Picker(selection: $settings.translationTarget) {
                        Text("English").tag("en")
                        Text("Japanese").tag("ja")
                        Text("Korean").tag("ko")
                        Text("Spanish").tag("es")
                        Text("French").tag("fr")
                        Text("Mandarin Chinese").tag("zh")
                    } label: {
                        Label("To", systemImage: "flag")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}
