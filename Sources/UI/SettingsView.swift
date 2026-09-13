import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    
    var body: some View {
        TabView {
            appearanceTab
                .tabItem {
                    Label("Appearance", systemImage: "paintpalette")
                }
            
            translationTab
                .tabItem {
                    Label("Translation", systemImage: "character.book.closed")
                }
        }
        .padding(20)
        .frame(minWidth: 450, minHeight: 350)
    }
    
    private var appearanceTab: some View {
        ScrollView {
            VStack {
                Form {
            Section {
                Slider(value: $settings.fontSize, in: 12...48, step: 1) {
                    Text("Font Size (\(Int(settings.fontSize))pt)")
                }
                
                ColorPicker("Text Color", selection: Binding(
                    get: { Color(hex: settings.textColorHex) },
                    set: { settings.textColorHex = $0.toHex() ?? "#FFFFFF" }
                ))
                
                Picker("Typography", selection: $settings.typography) {
                    Text("System").tag("system")
                    Text("Rounded").tag("rounded")
                    Text("Monospaced").tag("monospaced")
                    Text("Serif").tag("serif")
                }
                
                Picker("Alignment", selection: $settings.alignment) {
                    Text("Left").tag("left")
                    Text("Center").tag("center")
                    Text("Right").tag("right")
                }
                
                Picker("Line Layout", selection: $settings.lineLayout) {
                    Text("Single Line").tag("single")
                    Text("Two Lines").tag("two")
                    Text("Three Lines").tag("three")
                }
            } header: {
                Text("Text Options")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            Section {
                Toggle("Show Background", isOn: $settings.showBackground)
                
                if settings.showBackground {
                    ColorPicker("Background Color", selection: Binding(
                        get: { Color(hex: settings.backgroundColorHex) },
                        set: { settings.backgroundColorHex = $0.toHex() ?? "#000000" }
                    ))
                    
                    Slider(value: $settings.backgroundOpacity, in: 0...1, step: 0.1) {
                        Text("Background Opacity")
                    }
                }
            } header: {
                Text("Background Options")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            Section {
                Toggle("Show Timestamps in Full Lyrics", isOn: $settings.showTimestampsInMenu)
            } header: {
                Text("Menu Options")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }
            }
            Spacer()
            }
        }
        .padding()
    }
    
    private var translationTab: some View {
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

// MARK: - Color Hex Extensions
extension Color {
    func toHex() -> String? {
        guard let components = NSColor(self).usingColorSpace(.sRGB)?.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

@MainActor
class SettingsWindowManager {
    static let shared = SettingsWindowManager()
    var window: NSWindow?
    
    func show() {
        if window == nil {
            let settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 350),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            settingsWindow.minSize = NSSize(width: 450, height: 350)
            settingsWindow.title = "Settings"
            settingsWindow.contentView = NSHostingView(rootView: SettingsView())
            settingsWindow.isReleasedWhenClosed = false
            self.window = settingsWindow
        }
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
