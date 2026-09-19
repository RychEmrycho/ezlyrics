import SwiftUI

struct MenuBarSearchSection: View {
    @ObservedObject var syncEngine: SyncEngine
    @ObservedObject var searchViewModel: SearchViewModel
    
    @State private var searchQuery = ""
    @State private var searchResults: [LyricSearchResult] = []
    @State private var isSearching = false
    @State private var isShowingSearchResults = false
    @State private var lastSeenSong = ""
    
    var body: some View {
        VStack(spacing: 0) {
            if let recommended = searchViewModel.recommendedResponse {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommended")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    SearchResultRow(result: recommended, isApplied: syncEngine.currentLyrics?.sourceID == recommended.id) {
                        applyOverride(recommended)
                    }
                }
                .padding(.vertical, 4)
                
                Divider()
            }
            
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
            
            if !searchResults.isEmpty || searchViewModel.recommendedResponse != nil {
                DisclosureGroup(isExpanded: $isShowingSearchResults) {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if !searchResults.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(searchResults, id: \.id) { result in
                                        SearchResultRow(result: result, isApplied: syncEngine.currentLyrics?.sourceID == result.id) {
                                            applyOverride(result)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                    }
                    .frame(maxHeight: 200)
                    .clipped()
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
        }
        .onAppear {
            if let track = syncEngine.currentTrack {
                let trackStr = "\(track.artist) \(track.title)"
                if trackStr != lastSeenSong {
                    let initialQuery = searchViewModel.lastAutoSearchQuery.isEmpty ? trackStr : searchViewModel.lastAutoSearchQuery
                    searchQuery = initialQuery
                    lastSeenSong = trackStr
                    performSearch()
                } else if searchResults.isEmpty {
                    performSearch()
                }
            }
        }
        .onChange(of: syncEngine.currentTrack) { _, newTrack in
            if let track = newTrack {
                let trackStr = "\(track.artist) \(track.title)"
                if trackStr != lastSeenSong {
                    searchResults = []
                }
            }
        }
        .onChange(of: searchViewModel.autoSearchTrigger) { _, _ in
            let query = searchViewModel.lastAutoSearchQuery
            if !query.isEmpty {
                searchQuery = query
                if let track = syncEngine.currentTrack {
                    lastSeenSong = "\(track.artist) \(track.title)"
                }
                performSearch()
            }
        }
    }
    
    private func performSearch(expandResults: Bool = false) {
        guard !searchQuery.isEmpty else { return }
        isSearching = true
        Task { @MainActor in
            do {
                let results = try await LyricsService.shared.searchLyrics(query: searchQuery)
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
    
    private func applyOverride(_ result: LyricSearchResult) {
        Task { @MainActor in
            do {
                let parsed = try await LyricsService.shared.fetchLyrics(for: result)
                
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
            } catch {
                print("Failed to fetch override lyrics: \(error)")
            }
        }
    }
}
