import Cocoa
import SwiftUI

@MainActor
class SettingsWindowController {
    static let shared = SettingsWindowController()
    var window: NSWindow?
    
    func show() {
        if window == nil {
            let settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 550, height: 400),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            settingsWindow.minSize = NSSize(width: 550, height: 400)
            settingsWindow.title = "Settings"
            settingsWindow.titlebarAppearsTransparent = true
            settingsWindow.isOpaque = false
            settingsWindow.backgroundColor = .clear
            
            // We use a custom NSHostingView that includes an NSVisualEffectView in SwiftUI
            settingsWindow.contentView = NSHostingView(rootView: SettingsView())
            settingsWindow.isReleasedWhenClosed = false
            self.window = settingsWindow
        }
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
