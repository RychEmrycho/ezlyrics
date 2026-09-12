import SwiftUI
import AppKit
@preconcurrency import Translation

struct ManualOverrideView: View {
    @ObservedObject var syncEngine: SyncEngine
    @ObservedObject private var settings = SettingsManager.shared
    @State private var searchQuery = ""
    @State private var searchResults: [LRCLIBResponse] = []
    @State private var isSearching = false
    @State private var lastSeenSong = ""
    @State private var translatedLines: [UUID: String] = [:]
    @State private var isAutoFollowing = true
    @State private var scrollMonitor: Any?
    
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
            
            Toggle("Show Lyrics Overlay", isOn: $settings.showOverlay)
                .padding(.top, 4)

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
            
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(searchResults, id: \.id) { result in
                        Button(action: {
                            applyOverride(result)
                        }) {
                            VStack(alignment: .leading) {
                                Text("\(result.artistName) - \(result.trackName)")
                                    .font(.body)
                                Text("Duration: \(Int(result.duration ?? 0))s • \(result.syncedLyrics != nil ? "Synced" : "Plain")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxHeight: 200)
            
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
                                isAutoFollowing = true
                                if let activeId = syncEngine.activeLine?.id {
                                    withAnimation {
                                        proxy.scrollTo(activeId, anchor: .center)
                                    }
                                }
                            }) {
                                Image(systemName: isAutoFollowing ? "location.fill" : "location")
                                    .foregroundColor(isAutoFollowing ? .accentColor : .primary)
                            }
                            .buttonStyle(.plain)
                            .help(isAutoFollowing ? "Following active line" : "Follow active line")
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
                    .frame(maxHeight: 300)
                    .onChange(of: syncEngine.activeLine?.id) { _, newId in
                        if isAutoFollowing, let newId = newId {
                            withAnimation {
                                proxy.scrollTo(newId, anchor: .center)
                            }
                        }
                    }
                    }
                }
                Divider()
            }
            
            Button("Settings") {
                openSettings()
            }
            
            Button("Quit ezlyrics") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.bottom, 8)
        }
        .padding()
        .onAppear {
            scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                if isAutoFollowing {
                    DispatchQueue.main.async {
                        isAutoFollowing = false
                    }
                }
                return event
            }
            
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
            if let monitor = scrollMonitor {
                NSEvent.removeMonitor(monitor)
            }
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

