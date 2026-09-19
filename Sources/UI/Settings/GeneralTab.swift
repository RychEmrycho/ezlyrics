import SwiftUI

struct GeneralTab: View {
    @ObservedObject var settings: UserPreferences
    
    var body: some View {
        Form {
            Section(header: Text("Lyrics Provider")) {
                Picker("Provider", selection: $settings.lyricProvider) {
                    ForEach(LyricsService.shared.availableProviders, id: \.name) { provider in
                        Text(provider.name).tag(provider.name)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Text("The selected provider will be exclusively used to search and fetch lyrics.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
