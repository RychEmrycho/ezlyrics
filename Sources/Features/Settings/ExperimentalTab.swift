import SwiftUI

struct ExperimentalTab: View {
    @ObservedObject var settings: UserPreferences
    
    var body: some View {
        Form {
            Section(header: Text("Fun Mode (Experimental)").font(.headline)) {
                Text("Warning: These features are purely for fun and might get weird! 🎤✨🎶")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle("Bouncing Singer Emoji", isOn: $settings.funModeBouncingSinger)
                Toggle("Disco Gradient Text", isOn: $settings.funModeDiscoGradient)
                Toggle("Floating Cartoon Notes", isOn: $settings.funModeFloatingNotes)
                Toggle("Confetti Explosions", isOn: $settings.funModeConfetti)
                Toggle("Wobbly Lyrics", isOn: $settings.funModeWobblySinger)
                Toggle("Nyan Cat Mode", isOn: $settings.funModeNyanCat)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}
