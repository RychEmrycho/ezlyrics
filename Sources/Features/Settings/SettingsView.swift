import SwiftUI
import AppKit

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct SettingsView: View {
    @ObservedObject var settings = UserPreferences.shared
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main unified glassy background behind everything
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
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
            
            // This blur bar sits at the top to frost the scrolling content
            // before it reaches the transparent native toolbar.
            // It gets drawn below the AppKit NSToolbar text automatically.
            VisualEffectView(material: .titlebar, blendingMode: .withinWindow)
                .frame(height: 38)
                .ignoresSafeArea(edges: .top)
        }
        .frame(minWidth: 450, minHeight: 400)
    }
}

