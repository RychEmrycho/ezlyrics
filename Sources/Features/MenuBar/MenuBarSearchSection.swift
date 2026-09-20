import SwiftUI

struct MenuBarSearchSection: View {
    @ObservedObject var playbackVM: PlaybackViewModel
    @ObservedObject var menuBarVM: MenuBarViewModel
    
    @State private var isShowingSearchResults = false
    @State private var lastSeenSong = ""
    @FocusState private var isSearchFocused: Bool
    @State private var isAlternativesHovered = false
    
    var body: some View {
        VStack(spacing: 0) {
            let hasRecommended = menuBarVM.recommendedResult != nil
            let hasSearchResults = !menuBarVM.searchResults.isEmpty
            
            // Search Bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search lyrics...", text: $menuBarVM.searchQuery)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .onSubmit {
                        performSearch(expandResults: true)
                    }
                    .help("Manually search for lyrics if the auto-detected ones are incorrect")
                
                if menuBarVM.isSearching {
                    ProgressView()
                        .controlSize(.small)
                } else if !menuBarVM.searchQuery.isEmpty {
                    Button(action: {
                        menuBarVM.searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, (hasRecommended || hasSearchResults) ? 8 : 0)
            
            // Results
            if hasRecommended || hasSearchResults {
                Divider()
                    .opacity(0.5)
                    .padding(.bottom, 8)
                
                if hasRecommended, let recommended = menuBarVM.recommendedResult {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Best Match")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                        
                        SearchResultRow(result: recommended, isApplied: playbackVM.currentLyrics?.sourceID == recommended.id) {
                            menuBarVM.applyOverride(recommended)
                        }
                    }
                    .padding(.bottom, hasSearchResults ? 8 : 0)
                }
                
                if hasSearchResults {
                    let filteredResults = menuBarVM.searchResults.filter { result in
                        if hasRecommended, let recommended = menuBarVM.recommendedResult {
                            return result.id != recommended.id
                        }
                        return true
                    }
                    
                    if !filteredResults.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Button(action: {
                                isShowingSearchResults.toggle()
                            }) {
                                HStack {
                                    Text("Alternatives (\(filteredResults.count))")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Image(systemName: isShowingSearchResults ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .background(isAlternativesHovered ? Color.primary.opacity(0.06) : Color.clear)
                                .cornerRadius(6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .onHover { isAlternativesHovered = $0 }
                            
                            if isShowingSearchResults {
                                // If we have 4 or fewer results, just render them in a VStack.
                                // This perfectly hugs the content (no centering bugs, no GeometryReader)
                                // and easily fits in the popover.
                                if filteredResults.count <= 4 {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(filteredResults) { result in
                                            SearchResultRow(result: result, isApplied: playbackVM.currentLyrics?.sourceID == result.id) {
                                                menuBarVM.applyOverride(result)
                                            }
                                        }
                                    }
                                    .padding(.top, 4)
                                    .padding(.horizontal, 2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    // If we have many results, use a ScrollView with a fixed height.
                                    // Since content > 200pt, NSScrollView will never center it.
                                    ScrollView {
                                        LazyVStack(alignment: .leading, spacing: 4) {
                                            ForEach(filteredResults) { result in
                                                SearchResultRow(result: result, isApplied: playbackVM.currentLyrics?.sourceID == result.id) {
                                                    menuBarVM.applyOverride(result)
                                                }
                                            }
                                        }
                                        .padding(.top, 4)
                                        .padding(.horizontal, 2)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .frame(height: 200)
                                    .clipped()
                                }
                            }
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PopoverDidOpen"))) { _ in
            isSearchFocused = false
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
            isShowingSearchResults = false
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
