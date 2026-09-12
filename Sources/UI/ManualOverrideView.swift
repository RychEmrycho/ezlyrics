import SwiftUI
import AppKit
@preconcurrency import Translation

@MainActor
class ScrollMonitorState: ObservableObject {
    @Published var isAutoFollowing = true
    @Published var isHoveringLyrics = false
    private var scrollMonitor: Any?

    func startMonitoring() {
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self = self else { return event }
            if self.isAutoFollowing && self.isHoveringLyrics {
                DispatchQueue.main.async {
                    self.isAutoFollowing = false
                }
            }
            return event
        }
    }

    func stopMonitoring() {
        if let monitor = scrollMonitor {
            NSEvent.removeMonitor(monitor)
            scrollMonitor = nil
        }
    }
}

struct ManualOverrideView: View {
    @ObservedObject var syncEngine: SyncEngine
    @ObservedObject private var settings = SettingsManager.shared
    @State private var searchQuery = ""
    @State private var searchResults: [LRCLIBResponse] = []
    @State private var isSearching = false
    @State private var lastSeenSong = ""
    @State private var translatedLines: [UUID: String] = [:]
    @StateObject private var scrollState = ScrollMonitorState()
    @State private var isShowingSearchResults = false
    
    @State private var offsetInput: String = "0"
    
    var body: some View {
        VStack {
            Text("Now Playing")
                .font(.headline)
            if let track = syncEngine.currentTrack {
                Text("\(track.artist) - \(track.title)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Nothing playing")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack {
                TextField("Search LRCLIB...", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        performSearch()
                    }
                Button("Search") {
                    performSearch()
                }
            }
            .padding(.top, 8)
            
            if isSearching {
                ProgressView()
                    .padding()
            }
            
            if !searchResults.isEmpty {
                DisclosureGroup(isExpanded: $isShowingSearchResults) {
                    ScrollView {
                        LazyVStack(alignment: .leading) {
                            ForEach(searchResults, id: \.id) { result in
                                SearchResultRow(result: result) {
                                    applyOverride(result)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .frame(maxHeight: 200)
                } label: {
                    Text("Search Results")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                isShowingSearchResults.toggle()
                            }
                        }
                }
            }
            
            Divider()
            
            HStack {
                Text("Sync Offset:")
                    .font(.headline)
                Spacer()
                
                Button(action: { adjustOffset(by: -0.1) }) {
                    Image(systemName: "minus.square")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                TextField("Offset", text: $offsetInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)
                    .onSubmit {
                        applyOffset()
                    }
                
                Button(action: { adjustOffset(by: 0.1) }) {
                    Image(systemName: "plus.square")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Text("ms")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                
                Button(action: { syncEngine.userOffset = 0 }) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
            }
            .padding(.vertical, 4)
            
            if let lyrics = syncEngine.currentLyrics, lyrics.isSynced {
                VStack(alignment: .leading, spacing: 4) {
                    ScrollViewReader { proxy in
                        HStack {
                            Text("Sync to Line:")
                                .font(.headline)
                            Spacer()
                            
                            Button(action: {
                                scrollState.isAutoFollowing = true
                                if let activeId = syncEngine.activeLine?.id {
                                    withAnimation {
                                        proxy.scrollTo(activeId, anchor: .center)
                                    }
                                }
                            }) {
                                Image(systemName: scrollState.isAutoFollowing ? "location.fill" : "location")
                                    .foregroundColor(scrollState.isAutoFollowing ? .accentColor : .primary)
                            }
                            .buttonStyle(.plain)
                            .help(scrollState.isAutoFollowing ? "Following active line" : "Follow active line")
                            .padding(.trailing, 4)
                            
                            if settings.enableTranslation {
                                Picker("", selection: $settings.translationSource) {
                                    Text("Auto").tag("auto")
                                    Text("JA").tag("ja")
                                    Text("KO").tag("ko")
                                    Text("ZH").tag("zh")
                                    Text("ES").tag("es")
                                    Text("FR").tag("fr")
                                    Text("PT").tag("pt")
                                    Text("DE").tag("de")
                                    Text("IT").tag("it")
                                    Text("RU").tag("ru")
                                }
                                .pickerStyle(.menu)
                                .frame(width: 70)
                                .help("Translation source language")
                            }
                        }
                        .padding(.top, 4)
                        
                        ScrollView {
                        LazyVStack(alignment: .leading) {
                            ForEach(lyrics.lines) { line in
                                Button(action: {
                                    syncToLine(line)
                                }) {
                                    VStack(alignment: .leading, spacing: 1) {
                                        if settings.enableRomanization, let romanized = Romanizer.romanize(line.text) {
                                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                                Image(systemName: "waveform")
                                                    .font(.system(size: 10, weight: .semibold))
                                                    .foregroundColor(syncEngine.activeLine?.id == line.id ? .white : .white.opacity(0.6))
                                                
                                                Text(romanized.isEmpty ? "♫" : romanized)
                                                    .font(.body)
                                                    .multilineTextAlignment(.leading)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .foregroundColor(syncEngine.activeLine?.id == line.id ? .accentColor : .primary)
                                            }
                                            
                                            Text(line.text)
                                                .font(.caption)
                                                .multilineTextAlignment(.leading)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text(line.text.isEmpty ? "♫" : line.text)
                                                .font(.body)
                                                .multilineTextAlignment(.leading)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .foregroundColor(syncEngine.activeLine?.id == line.id ? .accentColor : .primary)
                                        }
                                        
                                        if settings.enableTranslation, let translated = translatedLines[line.id], !translated.isEmpty {
                                            HStack(alignment: .top, spacing: 3) {
                                                Image(systemName: "translate")
                                                    .font(.system(size: 9))
                                                    .padding(.top, 1)
                                                Text(translated)
                                                    .font(.caption)
                                                    .multilineTextAlignment(.leading)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                            .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .onHover { scrollState.isHoveringLyrics = $0 }
                    .frame(maxHeight: 300)
                    .onChange(of: syncEngine.activeLine?.id) { _, newId in
                        if scrollState.isAutoFollowing, let newId = newId {
                            withAnimation {
                                proxy.scrollTo(newId, anchor: .center)
                            }
                        }
                    }
                    }
                }
                Divider()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                MenuToggleRow(title: "Show Lyric", iconName: "text.quote", isOn: $settings.showOverlay)
                MenuItemRow(title: "Setting", iconName: "gearshape") {
                    openSettings()
                }
                MenuItemRow(title: "Quit", iconName: "power") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding()
        .frame(width: 400, height: 650)
        .onAppear {
            scrollState.startMonitoring()
            
            updateOffsetText(from: syncEngine.userOffset)
            if let track = syncEngine.currentTrack {
                let trackStr = "\(track.artist) \(track.title)"
                searchQuery = trackStr
                lastSeenSong = trackStr
                if searchResults.isEmpty {
                    performSearch()
                }
            }
        }
        .onDisappear {
            scrollState.stopMonitoring()
        }
        .onChange(of: syncEngine.currentTrack) { _, newTrack in
            if let track = newTrack {
                let trackStr = "\(track.artist) \(track.title)"
                if trackStr != lastSeenSong {
                    searchQuery = trackStr
                    lastSeenSong = trackStr
                    performSearch()
                }
            }
        }
        .onChange(of: syncEngine.userOffset) { _, newValue in
            updateOffsetText(from: newValue)
        }
        .applyBatchTranslation(
            lines: syncEngine.currentLyrics?.lines ?? [],
            detectedLanguage: syncEngine.currentLyrics?.detectedLanguage,
            isEnabled: settings.enableTranslation,
            sourceLanguage: settings.translationSource,
            targetLanguage: settings.translationTarget,
            translatedLines: $translatedLines
        )
    }
    private func adjustOffset(by step: Double) {
        syncEngine.userOffset += step
    }
    
    private func applyOffset() {
        let clean = offsetInput.trimmingCharacters(in: .whitespaces)
        let raw = Double(clean) ?? 0
        let val = raw / 1000.0
        
        if syncEngine.userOffset != val {
            syncEngine.userOffset = val
        }
    }

    private func updateOffsetText(from val: Double) {
        let ms = Int(round(val * 1000))
        offsetInput = "\(ms)"
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        isSearching = true
        Task { @MainActor in
            do {
                let results = try await LRCLIBClient.shared.searchLyrics(query: searchQuery)
                self.searchResults = results
                if !results.isEmpty {
                    self.isShowingSearchResults = true
                }
            } catch {
                print("Search failed: \(error)")
                self.searchResults = []
            }
            self.isSearching = false
        }
    }
    
    private func applyOverride(_ result: LRCLIBResponse) {
        let parsed = LRCParser.parse(plain: result.plainLyrics, synced: result.syncedLyrics, trackName: result.trackName, artistName: result.artistName)
        
        // Save to cache
        if let track = syncEngine.currentTrack {
            LyricsCache.shared.cache(lyrics: parsed, artist: track.artist, title: track.title)
        } else {
            syncEngine.currentTrack = NowPlayingTrack(
                artist: result.artistName,
                title: result.trackName,
                duration: result.duration ?? 0,
                elapsedTime: 0,
                isPlaying: true,
                lastUpdatedTime: Date().timeIntervalSinceReferenceDate
            )
        }
        syncEngine.currentLyrics = parsed
    }
    
    private func syncToLine(_ line: LyricLine) {
        if let track = syncEngine.currentTrack {
            var currentElapsed = track.elapsedTime
            if track.isPlaying {
                let timeSinceLastUpdate = Date().timeIntervalSinceReferenceDate - track.lastUpdatedTime
                currentElapsed += timeSinceLastUpdate
            }
            syncEngine.userOffset = line.timestamp - currentElapsed
        }
    }
    
    private func openSettings() {
        SettingsWindowManager.shared.show()
    }
}

struct SearchResultRow: View {
    let result: LRCLIBResponse
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                Text("\(result.artistName) - \(result.trackName)")
                    .font(.body)
                Text("Duration: \(Int(result.duration ?? 0))s • \(result.syncedLyrics != nil ? "Synced" : "Plain")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
            .background(isHovered ? Color.secondary.opacity(0.2) : Color.clear)
            .cornerRadius(4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct MenuItemRow: View {
    let title: String
    let iconName: String
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: iconName)
                    .frame(width: 16, alignment: .center)
                Text(title)
            }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(isHovered ? Color.accentColor : Color.clear)
                .foregroundColor(isHovered ? .white : .primary)
                .cornerRadius(4)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

struct MenuToggleRow: View {
    let title: String
    let iconName: String
    @Binding var isOn: Bool
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .frame(width: 16, alignment: .center)
            Text(title)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .scaleEffect(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isHovered ? Color.accentColor : Color.clear)
        .foregroundColor(isHovered ? .white : .primary)
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onTapGesture {
            isOn.toggle()
        }
        .onHover { isHovered = $0 }
    }
}
