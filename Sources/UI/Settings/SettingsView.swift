import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = UserPreferences.shared
    
    var body: some View {
        TabView {
            AppearanceTab(settings: settings)
                .tabItem {
                    Label("Appearance", systemImage: "paintpalette")
                }
            
            TranslationTab(settings: settings)
                .tabItem {
                    Label("Translation", systemImage: "character.book.closed")
                }
            
            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .padding(20)
        .frame(minWidth: 450, minHeight: 350)
    }
}
