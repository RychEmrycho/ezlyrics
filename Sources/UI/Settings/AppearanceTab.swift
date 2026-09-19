import SwiftUI

struct AppearanceTab: View {
    @ObservedObject var settings: UserPreferences
    
    var body: some View {
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
}
