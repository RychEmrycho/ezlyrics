import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var syncEngine: SyncEngine
    @ObservedObject var searchViewModel: SearchViewModel
    @ObservedObject private var settings = UserPreferences.shared
    @StateObject private var scrollState = ScrollMonitorState()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            if settings.isAppEnabled {
                MenuBarNowPlayingHeader(track: syncEngine.currentTrack)
                
                Divider()
                
                MenuBarSearchSection(
                    syncEngine: syncEngine,
                    searchViewModel: searchViewModel
                )
                
                Divider()
                
                if let lyrics = syncEngine.currentLyrics, !lyrics.lines.isEmpty {
                    MenuBarLyricsViewer(
                        syncEngine: syncEngine,
                        lyrics: lyrics,
                        scrollState: scrollState
                    )
                    
                    Divider()
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    MenuBarSyncOffsetView(syncEngine: syncEngine)
                    
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

typealias ManualOverrideView = MenuBarView
