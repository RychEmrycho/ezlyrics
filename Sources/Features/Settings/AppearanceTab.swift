import SwiftUI

struct AppearanceTab: View {
    @ObservedObject var settings: UserPreferences
    
    var body: some View {
        Form {
            Section("Overlay Text") {
                Slider(value: $settings.fontSize, in: 12...48, step: 1) {
                    Label("Font Size (\(Int(settings.fontSize))pt)", systemImage: "textformat.size")
                }
                
                ColorPicker(selection: Binding(
                    get: { Color(hex: settings.textColorHex) },
                    set: { settings.textColorHex = $0.toHex() ?? "#FFFFFF" }
                )) {
                    Label("Text Color", systemImage: "paintpalette")
                }
                
                Picker(selection: $settings.typography) {
                    Text("System").tag("system")
                    Text("Rounded").tag("rounded")
                    Text("Monospaced").tag("monospaced")
                    Text("Serif").tag("serif")
                } label: {
                    Label("Typography", systemImage: "textformat")
                }
                
                Picker(selection: $settings.alignment) {
                    Text("Left").tag("left")
                    Text("Center").tag("center")
                    Text("Right").tag("right")
                } label: {
                    Label("Alignment", systemImage: "text.alignleft")
                }
                
                Picker(selection: $settings.lineLayout) {
                    Text("Single Line").tag("single")
                    Text("Two Lines").tag("two")
                    Text("Three Lines").tag("three")
                } label: {
                    Label("Line Layout", systemImage: "lineweight")
                }
            }
            
            Section {
                Text("Note: Enabling Romanization or Translation may override the Line Layout setting.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Overlay Background") {
                Toggle(isOn: $settings.showBackground) {
                    Label("Show Background", systemImage: "square.fill")
                }
                
                if settings.showBackground {
                    ColorPicker(selection: Binding(
                        get: { Color(hex: settings.backgroundColorHex) },
                        set: { settings.backgroundColorHex = $0.toHex() ?? "#000000" }
                    )) {
                        Label("Background Color", systemImage: "drop.fill")
                    }
                    
                    Slider(value: $settings.backgroundOpacity, in: 0...1, step: 0.1) {
                        Label("Opacity", systemImage: "circle.lefthalf.filled")
                    }
                }
            }
            
            Section("Menu Bar") {
                Toggle(isOn: $settings.showTimestampsInMenu) {
                    Label("Show Timestamps in Full Lyrics", systemImage: "clock")
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}
