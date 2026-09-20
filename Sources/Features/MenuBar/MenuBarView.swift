import SwiftUI
import AppKit

struct MenuBarIconButton: View {
    let iconName: String
    let title: String
    let isOn: Bool
    let color: Color
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isOn ? .white : (isHovered ? .primary : .secondary))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isOn ? .white.opacity(0.9) : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isOn ? color : (isHovered ? Color.primary.opacity(0.1) : Color.primary.opacity(0.04)))
            .cornerRadius(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(title)
        .onHover { isHovered = $0 }
    }
}

struct MenuCard<Content: View>: View {
    let content: () -> Content
    var body: some View {
        content()
            .padding(12)
            .background(Color.primary.opacity(0.04))
            .cornerRadius(12)
    }
}

struct MenuBarView: View {
    @ObservedObject var playbackVM: PlaybackViewModel
    @ObservedObject var menuBarVM: MenuBarViewModel
    @ObservedObject private var settings = UserPreferences.shared
    @StateObject private var scrollState = ScrollMonitorState()
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var dummyFocus: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            if settings.isAppEnabled {
                // Card 1: Player
                MenuCard {
                    MenuBarNowPlayingHeader(playbackVM: playbackVM)
                }
                
                // Card 2: Search Section
                if playbackVM.currentTrack != nil {
                    MenuCard {
                        MenuBarSearchSection(
                            playbackVM: playbackVM,
                            menuBarVM: menuBarVM
                        )
                    }
                }
                
                // Card 3: Lyrics Viewer & Adjust Timing
                if let lyrics = playbackVM.currentLyrics, !lyrics.lines.isEmpty {
                    MenuCard {
                        VStack(spacing: 12) {
                            MenuBarLyricsViewer(
                                playbackVM: playbackVM,
                                lyrics: lyrics,
                                scrollState: scrollState
                            )
                            .layoutPriority(-1)
                            
                            if lyrics.isSynced {
                                Divider()
                                    .opacity(0.5)
                                    
                                MenuBarSyncOffsetView(playbackVM: playbackVM)
                            }
                        }
                    }
                }
            }
            
            // Footer Toolbar
            HStack(spacing: 8) {
                MenuBarIconButton(
                    iconName: "power", 
                    title: "Enable", 
                    isOn: settings.isAppEnabled, 
                    color: .accentColor
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        settings.isAppEnabled.toggle()
                    }
                }
                
                if settings.isAppEnabled {
                    MenuBarIconButton(
                        iconName: "text.quote", 
                        title: "Overlay", 
                        isOn: settings.showOverlay, 
                        color: .accentColor
                    ) {
                        settings.showOverlay.toggle()
                    }
                    
                    MenuBarIconButton(
                        iconName: "gearshape", 
                        title: "Settings", 
                        isOn: false, 
                        color: .clear
                    ) {
                        openSettings()
                    }
                }
                
                MenuBarIconButton(
                    iconName: "xmark.circle", 
                    title: "Quit", 
                    isOn: false, 
                    color: .clear
                ) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(14)
        .frame(width: settings.isAppEnabled ? 420 : 300)
        .background(
            colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.3)
        )
        .background(
            // HACK: SwiftUI on macOS aggressively auto-focuses the first available TextField 
            // in a popover (which would be our Search bar). We create this invisible dummy 
            // TextField and focus it onAppear to prevent the Search bar from stealing focus 
            // and showing a blinking cursor immediately when the menu opens.
            TextField("", text: .constant(""))
                .frame(width: 0, height: 0)
                .opacity(0)
                .focused($dummyFocus)
        )
        .onAppear {
            scrollState.startMonitoring()
            dummyFocus = true
        }
        .onDisappear {
            scrollState.stopMonitoring()
        }
    }
    
    private func openSettings() {
        SettingsWindowController.shared.show()
    }
}
