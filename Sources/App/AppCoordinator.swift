import Cocoa
import SwiftUI
import Combine

/// The composition root — the single place that knows about all concrete types
/// and wires them together.
@MainActor
final class AppCoordinator {
    
    // Data Layer
    let client: LRCLIBClient
    let cache: LyricsCache
    let mediaRemote: MediaRemoteSystem
    let repository: LyricsRepositoryImpl
    
    // Presentation Layer
    let nowPlayingMonitor: NowPlayingMonitor
    let playbackVM: PlaybackViewModel
    let menuBarVM: MenuBarViewModel
    
    // UI Controllers
    var windowController: FloatingHUDWindowController!
    var menuBarController: MenuBarController!
    
    // Internal
    var cancellables = Set<AnyCancellable>()
    var hideHUDTask: Task<Void, Never>?
    
    init() {
        // Wire data layer
        client = LRCLIBClient()
        cache = LyricsCache()
        mediaRemote = MediaRemoteSystem()
        repository = LyricsRepositoryImpl(client: client, cache: cache)
        
        // Wire presentation layer
        nowPlayingMonitor = NowPlayingMonitor(provider: mediaRemote)
        playbackVM = PlaybackViewModel(repository: repository)
        menuBarVM = MenuBarViewModel(repository: repository)
        menuBarVM.playbackVM = playbackVM
        
        // Forward fetch results from playback to menubar
        playbackVM.onLyricsFetched = { [weak self] result in
            self?.menuBarVM.onLyricsFetched(result)
        }
    }
    
    func start() {
        // Setup overlay window
        let lyricsView = LyricsOverlayView(playbackVM: playbackVM)
        windowController = FloatingHUDWindowController(rootView: lyricsView)
        if UserPreferences.shared.showOverlay && nowPlayingMonitor.currentTrack?.isPlaying == true {
            windowController.showHUD()
        }
        
        if UserPreferences.shared.isAppEnabled {
            mediaRemote.start()
        }
        
        // React to settings changes
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                if UserPreferences.shared.isAppEnabled {
                    self.mediaRemote.start()
                    if UserPreferences.shared.showOverlay && self.nowPlayingMonitor.currentTrack != nil {
                        if self.nowPlayingMonitor.currentTrack?.isPlaying == true {
                            self.windowController.showHUD()
                        } else {
                            self.windowController.hideHUD()
                        }
                    } else {
                        self.windowController.hideHUD()
                    }
                } else {
                    self.mediaRemote.stop()
                    self.windowController.hideHUD()
                    self.playbackVM.currentTrack = nil
                    self.playbackVM.currentLyrics = nil
                }
            }
            .store(in: &cancellables)
        
        // Setup menu bar
        menuBarController = MenuBarController()
        menuBarController.setup(playbackVM: playbackVM, menuBarVM: menuBarVM)
        
        // Bind monitor → playback VM
        nowPlayingMonitor.$currentTrack
            .sink { [weak self] track in
                guard let self = self else { return }
                self.playbackVM.onTrackChanged(track)
                
                if let track = track {
                    if UserPreferences.shared.showOverlay && UserPreferences.shared.isAppEnabled {
                        self.hideHUDTask?.cancel()
                        if track.isPlaying {
                            self.windowController.showHUD()
                        } else {
                            self.windowController.hideHUD()
                        }
                    }
                } else {
                    self.hideHUDTask?.cancel()
                    self.windowController.hideHUD()
                }
            }
            .store(in: &cancellables)
        
        // React to lyrics changes for HUD visibility
        playbackVM.$currentLyrics
            .receive(on: RunLoop.main)
            .sink { [weak self] lyrics in
                guard let self = self else { return }
                self.hideHUDTask?.cancel()
                if let lyrics = lyrics {
                    if UserPreferences.shared.showOverlay && UserPreferences.shared.isAppEnabled {
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
}
