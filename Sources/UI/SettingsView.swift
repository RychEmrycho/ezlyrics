import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    
    var body: some View {
        ScrollView {
            Form {
                Section(header: Text("Appearance")) {
                    Slider(value: $settings.fontSize, in: 12...48, step: 1) {
                        Text("Font Size (\(Int(settings.fontSize))pt)")
                    }
                    
                    TextField("Text Color (Hex)", text: $settings.textColorHex)
                    
                    Toggle("Show Background", isOn: $settings.showBackground)
                    
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
                    
                    if settings.showBackground {
                        Slider(value: $settings.backgroundOpacity, in: 0...1, step: 0.1) {
                            Text("Background Opacity")
                        }
                    }
                }
                
                Section(header: Text("Translation")) {
                    Toggle("Romanization (JA / KO / ZH)", isOn: $settings.enableRomanization)
                    Toggle("Enable Translation", isOn: $settings.enableTranslation)
                    
                    if settings.enableTranslation {
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
                    }
                }
                
            }
            .padding()
        }
        .frame(width: 400, height: 480)
    }
}

@MainActor
class SettingsWindowManager {
    static let shared = SettingsWindowManager()
    var window: NSWindow?
    
    func show() {
        if window == nil {
            let settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
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
