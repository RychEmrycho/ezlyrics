import Foundation

/// Describes the result of a lyrics fetch operation.
/// This replaces the silent "empty result" pattern with an explicit state.
/// UI layers can check this to show appropriate messages.
enum LyricsFetchState: Equatable {
    /// Fetch is in progress
    case loading
    /// Successfully fetched lyrics
    case found(ParsedLyrics)
    /// No lyrics found (API returned nothing, or search yielded no matches)
    case notFound
    /// A network or decoding error occurred
    case error(String)
}
