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
    var hideHUDTask: Task<Void, Never>?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Setup Window
        let lyricsView = LyricsOverlayView(syncEngine: syncEngine)
        windowController = FloatingHUDWindowController(rootView: lyricsView)
        if SettingsManager.shared.showOverlay && nowPlayingMonitor.currentTrack?.isPlaying == true {
            windowController.showHUD()
        }
        
        if SettingsManager.shared.isAppEnabled {
            MediaRemoteWrapper.shared.startHelper()
        }
        
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                if SettingsManager.shared.isAppEnabled {
                    MediaRemoteWrapper.shared.startHelper()
                    if SettingsManager.shared.showOverlay && self.nowPlayingMonitor.currentTrack != nil {
                        if self.nowPlayingMonitor.currentTrack?.isPlaying == true {
                            self.windowController.showHUD()
                        } else {
                            self.windowController.hideHUD()
                        }
                    } else {
                        self.windowController.hideHUD()
                    }
                } else {
                    MediaRemoteWrapper.shared.stopHelper()
                    self.windowController.hideHUD()
                    self.syncEngine.currentTrack = nil
                    self.syncEngine.currentLyrics = nil
                }
            }
            .store(in: &cancellables)
        
        // Setup Menu Bar
        menuBarController = MenuBarController()
        menuBarController.setup(syncEngine: syncEngine)
        
        // Bind Monitor to SyncEngine
        nowPlayingMonitor.$currentTrack
            .sink { [weak self] track in
                guard let self = self else { return }
                self.syncEngine.currentTrack = track
                if let track = track {
                    self.fetchLyrics(for: track)
                    if SettingsManager.shared.showOverlay && SettingsManager.shared.isAppEnabled {
                        self.hideHUDTask?.cancel()
                        if track.isPlaying {
                            self.windowController.showHUD()
                        } else {
                            self.windowController.hideHUD()
                        }
                    }
                } else {
                    self.syncEngine.currentLyrics = nil
                    self.hideHUDTask?.cancel()
                    self.windowController.hideHUD()
                }
            }
            .store(in: &cancellables)
            
        syncEngine.$currentLyrics
            .receive(on: RunLoop.main)
            .sink { [weak self] lyrics in
                guard let self = self else { return }
                self.hideHUDTask?.cancel()
                if let lyrics = lyrics {
                    if SettingsManager.shared.showOverlay && SettingsManager.shared.isAppEnabled {
                        if self.nowPlayingMonitor.currentTrack?.isPlaying == true {
                            self.windowController.showHUD()
                        }
                        if !lyrics.isSynced {
                            self.hideHUDTask = Task {
                                try? await Task.sleep(nanoseconds: 3_000_000_000)
                                if !Task.isCancelled {
                                    self.windowController.hideHUD()
                                }
                            }
                        }
                    }
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
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let response = try await LRCLIBClient.shared.getLyrics(artist: track.artist, title: track.title, duration: track.duration)
                let parsed = LRCParser.parse(plain: response.plainLyrics, synced: response.syncedLyrics, trackName: response.trackName, artistName: response.artistName)
                LyricsCache.shared.cache(lyrics: parsed, artist: track.artist, title: track.title)
                self.syncEngine.currentLyrics = parsed
            } catch {
                do {
                    let results = try await LRCLIBClient.shared.searchLyrics(query: track.title)
                    if let bestMatch = results.first(where: { $0.syncedLyrics != nil || $0.plainLyrics != nil }) {
                        let parsed = LRCParser.parse(plain: bestMatch.plainLyrics, synced: bestMatch.syncedLyrics, trackName: bestMatch.trackName, artistName: bestMatch.artistName)
                        LyricsCache.shared.cache(lyrics: parsed, artist: track.artist, title: track.title)
                        self.syncEngine.currentLyrics = parsed
                    } else {
                        print("Failed to fetch lyrics: No lyrics found in search results.")
                        self.syncEngine.currentLyrics = ParsedLyrics(trackName: track.title, artistName: track.artist, isSynced: false, lines: [], detectedLanguage: nil)
                    }
                } catch {
                    print("Failed to fetch lyrics via search: \(error)")
                    self.syncEngine.currentLyrics = ParsedLyrics(trackName: track.title, artistName: track.artist, isSynced: false, lines: [], detectedLanguage: nil)
                }
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
