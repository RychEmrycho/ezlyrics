import Cocoa
import SwiftUI

@MainActor
class MenuBarController: NSObject {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    
    func setup(playbackVM: PlaybackViewModel, menuBarVM: MenuBarViewModel) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "music.note.list", accessibilityDescription: "ezlyrics")
            button.action = #selector(handleButtonAction(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        popover = NSPopover()
        popover.behavior = .transient
        
        let view = MenuBarView(playbackVM: playbackVM, menuBarVM: menuBarVM)
        popover.contentViewController = NSHostingController(rootView: view)
    }
    
    @objc func handleButtonAction(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            showRightClickMenu()
        } else {
            togglePopover(sender)
        }
    }
    
    func showRightClickMenu() {
        let menu = NSMenu()
        
        let showOverlayItem = NSMenuItem(title: UserPreferences.shared.showOverlay ? "Hide Overlay" : "Show Overlay", action: #selector(toggleShowOverlay), keyEquivalent: "")
        showOverlayItem.target = self
        menu.addItem(showOverlayItem)
        
        let enableItem = NSMenuItem(title: UserPreferences.shared.isAppEnabled ? "Disable ezlyrics" : "Enable ezlyrics", action: #selector(toggleEnable), keyEquivalent: "")
        enableItem.target = self
        menu.addItem(enableItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }
    
    @objc func toggleShowOverlay() {
        UserPreferences.shared.showOverlay.toggle()
    }
    
    @objc func toggleEnable() {
        UserPreferences.shared.isAppEnabled.toggle()
    }
    
    @objc func openSettings() {
        SettingsWindowController.shared.show()
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            if let button = statusItem.button {
                NSApp.activate(ignoringOtherApps: true)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
}
