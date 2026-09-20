import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var playbackVM: PlaybackViewModel
    @ObservedObject var menuBarVM: MenuBarViewModel
    @ObservedObject private var settings = UserPreferences.shared
    @StateObject private var scrollState = ScrollMonitorState()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            if settings.isAppEnabled {
                MenuBarNowPlayingHeader(track: playbackVM.currentTrack)
                
                Divider()
                
                MenuBarSearchSection(
                    playbackVM: playbackVM,
                    menuBarVM: menuBarVM
                )
                .layoutPriority(-1)
                
                Divider()
                
                if let lyrics = playbackVM.currentLyrics, !lyrics.lines.isEmpty {
                    MenuBarLyricsViewer(
                        playbackVM: playbackVM,
                        lyrics: lyrics,
                        scrollState: scrollState
                    )
                    .layoutPriority(-1)
                    
                    Divider()
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    MenuBarSyncOffsetView(playbackVM: playbackVM)
                    
                    Divider()
                    
                    MenuToggleRow(title: "Show Overlay", iconName: "text.quote", isOn: $settings.showOverlay)
                    MenuItemRow(title: "Settings", iconName: "gearshape") {
                        openSettings()
                    }
                }
            }
            
            if settings.isAppEnabled {
                Divider()
            }
            MenuToggleRow(title: "Enable ezlyrics", iconName: "power", isOn: $settings.isAppEnabled)
            MenuItemRow(title: "Quit", iconName: "xmark.circle") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: settings.isAppEnabled ? 400 : 250)
        .background(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.3))
        .onAppear {
            scrollState.startMonitoring()
        }
        .onDisappear {
            scrollState.stopMonitoring()
        }
    }
    
    private func openSettings() {
        SettingsWindowController.shared.show()
    }
}
