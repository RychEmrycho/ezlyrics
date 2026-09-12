import Cocoa
import SwiftUI
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var windowController: FloatingHUDWindowController!
    var menuBarController: MenuBarController!
    let syncEngine = SyncEngine()
    let nowPlayingMonitor = NowPlayingMonitor()
    var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Setup Window
        let lyricsView = LyricsOverlayView(syncEngine: syncEngine)
        windowController = FloatingHUDWindowController(rootView: lyricsView)
        windowController.showHUD()
        
        // Setup Menu Bar
        menuBarController = MenuBarController()
        menuBarController.setup(syncEngine: syncEngine)
        
        // Bind Monitor to SyncEngine
        nowPlayingMonitor.$currentTrack
            .sink { [weak self] track in
                self?.syncEngine.currentTrack = track
                if let track = track {
                    self?.fetchLyrics(for: track)
                } else {
                    self?.syncEngine.currentLyrics = nil
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchLyrics(for track: NowPlayingTrack) {
        // Check cache first
        if let cached = LyricsCache.shared.getCachedLyrics(artist: track.artist, title: track.title) {
            syncEngine.currentLyrics = cached
            return
        }
        
        // Otherwise fetch
        LRCLIBClient.shared.getLyrics(artist: track.artist, title: track.title, duration: track.duration) { [weak self] response in
            guard let response = response else { return }
            let parsed = LRCParser.parse(plain: response.plainLyrics, synced: response.syncedLyrics, trackName: response.trackName, artistName: response.artistName)
            LyricsCache.shared.cache(lyrics: parsed, artist: track.artist, title: track.title)
            DispatchQueue.main.async {
                self?.syncEngine.currentLyrics = parsed
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // hides from dock

// Setup a basic Edit menu to allow keyboard shortcuts (Cmd+C, Cmd+V, Cmd+A) in TextFields
let mainMenu = NSMenu()
let appMenuItem = NSMenuItem()
mainMenu.addItem(appMenuItem)
let appMenu = NSMenu()
appMenu.addItem(NSMenuItem(title: "Quit ezlyrics", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
appMenuItem.submenu = appMenu

let editMenuItem = NSMenuItem()
mainMenu.addItem(editMenuItem)
let editMenu = NSMenu(title: "Edit")
editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
editMenuItem.submenu = editMenu
app.mainMenu = mainMenu

app.run()
