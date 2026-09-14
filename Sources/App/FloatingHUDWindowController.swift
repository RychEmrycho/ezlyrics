import Cocoa
import SwiftUI

class HUDPanel: NSPanel {
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
    
    private var initialLocation: NSPoint?
    
    // Prevent macOS from clamping the window to the visible frame when dragging programmatically
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect
    }
    
    // Manual drag implementation to completely bypass Cocoa's menu bar snapping restrictions
    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown {
            initialLocation = event.locationInWindow
        } else if event.type == .leftMouseDragged, let initial = initialLocation {
            var newOrigin = self.frame.origin
            newOrigin.x += (event.locationInWindow.x - initial.x)
            newOrigin.y += (event.locationInWindow.y - initial.y)
            self.setFrameOrigin(newOrigin)
        } else if event.type == .leftMouseUp {
            initialLocation = nil
            self.saveFrame(usingName: "OverlayWindow")
        }
        super.sendEvent(event)
    }
}

@MainActor
class FloatingHUDWindowController: NSWindowController {
    
    init<V: View>(rootView: V) {
        let panel = HUDPanel(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 200),
            styleMask: [.nonactivatingPanel, .borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        
        // Allow dragging by clicking anywhere on the background
        panel.isMovableByWindowBackground = true
        
        let hostingView = NSHostingView(rootView: rootView)
        panel.contentView = hostingView
        
        panel.setFrameAutosaveName("OverlayWindow")
        
        super.init(window: panel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showHUD() {
        if let window = window {
            if !window.setFrameUsingName("OverlayWindow") {
                if let screen = NSScreen.main {
                    let frame = window.frame
                    let screenFrame = screen.visibleFrame
                    window.setFrameOrigin(NSPoint(x: screenFrame.midX - frame.width / 2, y: screenFrame.maxY - frame.height - 50))
                }
            }
        }
        window?.orderFront(nil)
    }
    
    func hideHUD() {
        window?.orderOut(nil)
    }
}
