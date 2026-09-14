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
    
    @State private var isAutoScrollingPlain = false
    @State private var plainScrollSpeedLevel: Int = 0
    @State private var currentPlainLineIndex: Int = 0
    @State private var autoScrollTask: Task<Void, Never>?
    
    var body: some View {
        VStack {
            if settings.isAppEnabled {
                Text("Now Playing")
                    .font(.headline)
            if let track = syncEngine.currentTrack {
                Text("\(track.artist) - \(track.title) (\(Int(track.duration))s)")
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
                        performSearch(expandResults: true)
                    }
                Button("Search") {
                    performSearch(expandResults: true)
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
                    .frame(minHeight: 150, maxHeight: 200)
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
            
            if let lyrics = syncEngine.currentLyrics, !lyrics.lines.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ScrollViewReader { proxy in
                        HStack {
                            Text("Full Lyrics:")
                                .font(.headline)
                            Spacer()
                            
                            if lyrics.isSynced {
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
                            }
                            
                            if !lyrics.isSynced {
                                Button(action: {
                                    toggleAutoScroll(proxy: proxy, lines: lyrics.lines)
                                }) {
                                    Image(systemName: isAutoScrollingPlain ? "pause.fill" : "play.fill")
                                        .foregroundColor(isAutoScrollingPlain ? .accentColor : .primary)
                                }
                                .buttonStyle(.plain)
                                .help(isAutoScrollingPlain ? "Pause auto-scroll" : "Start auto-scroll")
                                
                                Stepper(value: $plainScrollSpeedLevel, in: 0...10, step: 1) {
                                    Text(plainScrollSpeedLevel == 0 ? "Speed: Off" : "Speed: \(plainScrollSpeedLevel)")
                                        .font(.caption)
                                }
                                .frame(width: 80)
                                .padding(.trailing, 4)
                            }
                            
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
                                    if lyrics.isSynced {
                                        syncToLine(line)
                                    } else {
                                        if let idx = lyrics.lines.firstIndex(where: { $0.id == line.id }) {
                                            currentPlainLineIndex = idx
                                            withAnimation {
                                                proxy.scrollTo(line.id, anchor: .center)
                                            }
                                        }
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 1) {
                                        if settings.enableRomanization && settings.romanizationDisplayMode != "overlayOnly", let romanized = Romanizer.romanize(line.text) {
                                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                                if lyrics.isSynced {
                                                    Image(systemName: "waveform")
                                                        .font(.system(size: 10, weight: .semibold))
                                                        .foregroundColor(syncEngine.activeLine?.id == line.id ? .white : .white.opacity(0.6))
                                                } else if isLineActive(lyrics: lyrics, line: line) {
                                                    Image(systemName: "play.fill")
                                                        .font(.system(size: 10, weight: .semibold))
                                                        .foregroundColor(.accentColor)
                                                }
                                                
                                                if settings.showTimestampsInMenu && lyrics.isSynced {
                                                    Text(formatTimestamp(line.timestamp))
                                                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                Text(romanized.isEmpty ? "♫" : romanized)
                                                    .font(.body)
                                                    .multilineTextAlignment(.leading)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .foregroundColor(isLineActive(lyrics: lyrics, line: line) ? .accentColor : .primary)
                                            }
                                            
                                            Text(line.text)
                                                .font(.caption)
                                                .multilineTextAlignment(.leading)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .foregroundColor(.secondary)
                                        } else {
                                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                                if lyrics.isSynced {
                                                } else if isLineActive(lyrics: lyrics, line: line) {
                                                    Image(systemName: "play.fill")
                                                        .font(.system(size: 10, weight: .semibold))
                                                        .foregroundColor(.accentColor)
                                                }
                                                if settings.showTimestampsInMenu && lyrics.isSynced {
                                                    Text(formatTimestamp(line.timestamp))
                                                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                                                        .foregroundColor(.secondary)
                                                }
                                                Text(line.text.isEmpty ? "♫" : line.text)
                                                    .font(.body)
                                                    .multilineTextAlignment(.leading)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .foregroundColor(isLineActive(lyrics: lyrics, line: line) ? .accentColor : .primary)
                                            }
                                        }
                                        
                                        if settings.enableTranslation && settings.translationDisplayMode != "overlayOnly", let translated = translatedLines[line.id], !translated.isEmpty {
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
                    .frame(minHeight: 200, maxHeight: 300)
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
                
                Divider()
                
                MenuToggleRow(title: "Show Overlay", iconName: "text.quote", isOn: $settings.showOverlay)
                MenuItemRow(title: "Settings", iconName: "gearshape") {
                    openSettings()
                }
            } // end VStack
            } // end if settings.isAppEnabled
            
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
            isAutoScrollingPlain = false
            autoScrollTask?.cancel()
            autoScrollTask = nil
            currentPlainLineIndex = 0
            
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
            isEnabled: settings.enableTranslation && settings.translationDisplayMode != "overlayOnly",
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
    
    private func performSearch(expandResults: Bool = false) {
        guard !searchQuery.isEmpty else { return }
        isSearching = true
        Task { @MainActor in
            do {
                let results = try await LRCLIBClient.shared.searchLyrics(query: searchQuery)
                self.searchResults = results
                if !results.isEmpty && expandResults {
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
    
    private var waitTimeForScroll: Double {
        if plainScrollSpeedLevel == 0 {
            return .infinity
        }
        let times = [6.0, 5.0, 4.0, 3.5, 3.0, 2.5, 2.0, 1.5, 1.0, 0.5]
        let idx = max(0, min(times.count - 1, plainScrollSpeedLevel - 1))
        return times[idx]
    }
    
    private func formatTimestamp(_ time: TimeInterval) -> String {
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        let ms = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "[%02d:%02d.%02d]", mins, secs, ms)
    }
    
    private func isLineActive(lyrics: ParsedLyrics, line: LyricLine) -> Bool {
        if lyrics.isSynced {
            return syncEngine.activeLine?.id == line.id
        } else {
            return isAutoScrollingPlain && lyrics.lines.firstIndex(where: { $0.id == line.id }) == currentPlainLineIndex
        }
    }
    
    private func toggleAutoScroll(proxy: ScrollViewProxy, lines: [LyricLine]) {
        if isAutoScrollingPlain {
            isAutoScrollingPlain = false
            autoScrollTask?.cancel()
            autoScrollTask = nil
        } else {
            isAutoScrollingPlain = true
            autoScrollTask = Task {
                var accumulated: Double = 0
                let step: Double = 0.1
                while !Task.isCancelled && currentPlainLineIndex < lines.count - 1 {
                    try? await Task.sleep(nanoseconds: UInt64(step * 1_000_000_000))
                    accumulated += step
                    let waitTime = waitTimeForScroll
                    if accumulated >= waitTime {
                        accumulated = 0
                        currentPlainLineIndex += 1
                        let nextId = lines[currentPlainLineIndex].id
                        await MainActor.run {
                            withAnimation(.easeInOut) {
                                proxy.scrollTo(nextId, anchor: .center)
                            }
                        }
                    }
                }
                await MainActor.run {
                    isAutoScrollingPlain = false
                }
            }
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
