import Cocoa
import SwiftUI

@MainActor
class MenuBarController: NSObject {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    
    func setup(syncEngine: SyncEngine) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "music.note.list", accessibilityDescription: "ezlyrics")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        
        popover = NSPopover()
        popover.behavior = .transient
        
        let view = ManualOverrideView(syncEngine: syncEngine)
        popover.contentViewController = NSHostingController(rootView: view)
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
