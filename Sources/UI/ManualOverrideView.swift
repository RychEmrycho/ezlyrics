import SwiftUI

struct ManualOverrideView: View {
    @ObservedObject var syncEngine: SyncEngine
    @State private var searchQuery = ""
    @State private var searchResults: [LRCLIBResponse] = []
    @State private var isSearching = false
    @State private var lastSeenSong = ""
    
    enum OffsetUnit: String, CaseIterable {
        case ms, s
    }
    
    @State private var offsetInput: String = "0"
    @State private var offsetUnit: OffsetUnit = .ms
    
    var body: some View {
        VStack {
            Text("Now Playing")
                .font(.headline)
            if let track = syncEngine.currentTrack {
                Text("\(track.artist) - \(track.title)")
                    .font(.subheadline)
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
                TextField("Offset", text: $offsetInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)
                    .onSubmit {
                        applyOffset()
                    }
                
                Picker("", selection: $offsetUnit) {
                    Text("ms").tag(OffsetUnit.ms)
                    Text("s").tag(OffsetUnit.s)
                }
                .pickerStyle(.segmented)
                .frame(width: 80)
                .onChange(of: offsetUnit) { _, _ in
                    applyOffset()
                }
                
                Button(action: { syncEngine.userOffset = 0 }) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
            }
            .padding(.vertical, 4)
            
            if let lyrics = syncEngine.currentLyrics, lyrics.isSynced {
                VStack(alignment: .leading) {
                    Text("Sync to Line (Manual Jump):")
                        .font(.headline)
                        .padding(.top, 4)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading) {
                            ForEach(lyrics.lines) { line in
                                Button(action: {
                                    syncToLine(line)
                                }) {
                                    Text(line.text.isEmpty ? "♫" : line.text)
                                        .font(.body)
                                        .lineLimit(1)
                                        .padding(.vertical, 2)
                                        .contentShape(Rectangle())
                                        .foregroundColor(syncEngine.activeLine?.id == line.id ? .accentColor : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
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
    }
    
    private func applyOffset() {
        let clean = offsetInput.trimmingCharacters(in: .whitespaces)
        let raw = Double(clean) ?? 0
        
        let val: Double
        if offsetUnit == .ms {
            val = raw / 1000.0
        } else {
            val = raw
        }
        
        if syncEngine.userOffset != val {
            syncEngine.userOffset = val
        }
    }

    private func updateOffsetText(from val: Double) {
        let ms = Int(round(val * 1000))
        if ms == 0 {
            offsetInput = "0"
        } else if abs(ms) >= 1000 && ms % 1000 == 0 {
            offsetInput = "\(ms / 1000)"
            offsetUnit = .s
        } else {
            offsetInput = "\(ms)"
            offsetUnit = .ms
        }
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

