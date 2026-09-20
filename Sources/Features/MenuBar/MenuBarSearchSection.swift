import SwiftUI

struct MenuBarSearchSection: View {
    @ObservedObject var playbackVM: PlaybackViewModel
    @ObservedObject var menuBarVM: MenuBarViewModel
    
    @State private var isShowingSearchResults = false
    @State private var lastSeenSong = ""
    
    var body: some View {
        VStack(spacing: 0) {
            if let recommended = menuBarVM.recommendedResult {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommended")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    SearchResultRow(result: recommended, isApplied: playbackVM.currentLyrics?.sourceID == recommended.id) {
                        menuBarVM.applyOverride(recommended)
                    }
                }
                .padding(.vertical, 4)
                
                Divider()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Not the right lyrics?")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("Search lyrics...", text: $menuBarVM.searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            performSearch(expandResults: true)
                        }
                    Button("Search") {
                        performSearch(expandResults: true)
                    }
                }
            }
            .padding(.top, 8)
            
            if menuBarVM.isSearching {
                ProgressView()
                    .padding()
            }
            
            if !menuBarVM.searchResults.isEmpty || menuBarVM.recommendedResult != nil {
                DisclosureGroup(isExpanded: $isShowingSearchResults) {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if !menuBarVM.searchResults.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(menuBarVM.searchResults) { result in
                                        SearchResultRow(result: result, isApplied: playbackVM.currentLyrics?.sourceID == result.id) {
                                            menuBarVM.applyOverride(result)
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
            if let track = playbackVM.currentTrack {
                let trackStr = "\(track.artist) \(track.title)"
                if trackStr != lastSeenSong {
                    let initialQuery = menuBarVM.lastAutoSearchQuery.isEmpty ? trackStr : menuBarVM.lastAutoSearchQuery
                    menuBarVM.searchQuery = initialQuery
                    lastSeenSong = trackStr
                    performSearch()
                } else if menuBarVM.searchResults.isEmpty {
                    performSearch()
                }
            }
        }
        .onChange(of: playbackVM.currentTrack) { _, newTrack in
            if let track = newTrack {
                let trackStr = "\(track.artist) \(track.title)"
                if trackStr != lastSeenSong {
                    menuBarVM.searchResults = []
                }
            }
        }
        .onChange(of: menuBarVM.autoSearchTrigger) { _, _ in
            let query = menuBarVM.lastAutoSearchQuery
            if !query.isEmpty {
                menuBarVM.searchQuery = query
                if let track = playbackVM.currentTrack {
                    lastSeenSong = "\(track.artist) \(track.title)"
                }
                performSearch()
            }
        }
    }
    
    private func performSearch(expandResults: Bool = false) {
        Task { @MainActor in
            await menuBarVM.performSearch()
            if !menuBarVM.searchResults.isEmpty && expandResults {
                isShowingSearchResults = true
            }
        }
    }
}
