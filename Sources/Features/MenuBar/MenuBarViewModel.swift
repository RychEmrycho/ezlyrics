import Foundation
import Combine

@MainActor
class MenuBarViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching: Bool = false
    @Published var recommendedResult: SearchResult?
    @Published var lastAutoSearchQuery: String = ""
    @Published var autoSearchTrigger: UUID = UUID()
    
    private let repository: LyricsRepository
    
    /// Reference to the playback VM for applying overrides.
    weak var playbackVM: PlaybackViewModel?
    
    init(repository: LyricsRepository) {
        self.repository = repository
    }
    
    /// Called by the coordinator when lyrics are fetched, to update search state.
    func onLyricsFetched(_ result: FetchResult) {
        self.recommendedResult = result.recommendedResult
        self.lastAutoSearchQuery = result.searchQuery
        self.autoSearchTrigger = UUID()
    }
    
    func performSearch() async {
        guard !searchQuery.isEmpty else { return }
        isSearching = true
        do {
            let results = try await repository.searchLyrics(query: searchQuery)
            self.searchResults = results
        } catch {
            AppLogger.ui.error("Search failed: \(error)")
            self.searchResults = []
        }
        isSearching = false
    }
    
    func applyOverride(_ result: SearchResult) {
        guard let playbackVM = playbackVM else { return }
        Task { @MainActor in
            if let track = playbackVM.currentTrack {
                let parsed = await repository.applyOverride(result, for: track)
                playbackVM.currentLyrics = parsed
            } else {
                let syntheticTrack = Track(
                    artist: result.artistName,
                    title: result.trackName,
                    duration: result.duration ?? 0,
                    elapsedTime: 0,
                    isPlaying: true,
                    lastUpdatedTime: Date().timeIntervalSinceReferenceDate
                )
                playbackVM.currentTrack = syntheticTrack
                let parsed = await repository.applyOverride(result, for: syntheticTrack)
                playbackVM.currentLyrics = parsed
            }
        }
    }
}
