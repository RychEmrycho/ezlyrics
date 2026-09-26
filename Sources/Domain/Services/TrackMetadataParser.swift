import Foundation

/// Stateless parser that normalizes raw media metadata (artist/title strings)
/// into clean, search-friendly values. Handles platform quirks like YouTube
/// title formats, Japanese bracket conventions, and junk tags.
struct TrackMetadataParser {
    
    // MARK: - Pre-compiled Regexes
    
    // Matches Japanese title brackets
    private static let jpQuotesRegex = try! NSRegularExpression(pattern: "『(.*?)』|「(.*?)」")
    
    // Matches bracketed junk tags like [Official Music Video], (Lyrics), etc.
    private static let bracketedJunkRegex = "(?i)\\s*[\\(\\[].*?(official|lyric|visualizer|video|audio|mv).*?[\\)\\]]"
    
    // Matches trailing unbracketed junk tags
    private static let trailingJunkRegex = "(?i)\\s+(official\\s+)?(music\\s+video|lyric\\s+video|lyric|video|audio|visualizer|mv)\\s*$"
    
    // MARK: - Main Parsing
    
    /// Takes raw artist/title strings from the media system and returns cleaned, normalized values.
    static func parse(rawArtist: String, rawTitle: String) -> (artist: String, title: String) {
        var artist = rawArtist.trimmingCharacters(in: .whitespacesAndNewlines)
        var title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Extract titles from structural formats (Japanese brackets or "Artist - Title")
        if let jpParsed = extractJapaneseTitle(title: title) {
            artist = jpParsed.artist.isEmpty ? artist : jpParsed.artist
            title = jpParsed.title
        } else if let splitParsed = splitArtistAndTitle(title: title) {
            artist = splitParsed.artist
            title = splitParsed.title
        }
        
        // 2. Aggressively strip duplicate artist names from the beginning of the title
        title = stripDuplicateArtistPrefix(artist: artist, title: title)
        
        // 3. Strip search-ruining junk tags
        title = stripJunkTags(from: title)
        
        // 4. Strip surrounding quotes
        title = stripSurroundingQuotes(from: title)
        
        return (artist: artist, title: title)
    }
    
    // MARK: - Helper Rules
    
    /// Parses Japanese formatting like: "KANA-BOON 『ないものねだり』Music Video"
    private static func extractJapaneseTitle(title: String) -> (artist: String, title: String)? {
        let fullRange = NSRange(title.startIndex..., in: title)
        guard let match = jpQuotesRegex.firstMatch(in: title, range: fullRange),
              let matchRange = Range(match.range, in: title) else {
            return nil
        }
        
        // Everything before the brackets is usually the artist
        let prefixStr = String(title[..<matchRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Extract the contents of whichever bracket matched (Group 1 or Group 2)
        let extractedTitle: String
        if let range1 = Range(match.range(at: 1), in: title) {
            extractedTitle = String(title[range1])
        } else if let range2 = Range(match.range(at: 2), in: title) {
            extractedTitle = String(title[range2])
        } else {
            return nil
        }
        
        return (artist: prefixStr, title: extractedTitle)
    }
    
    /// Parses standard YouTube formatting: "Artist - Title"
    private static func splitArtistAndTitle(title: String) -> (artist: String, title: String)? {
        guard title.contains(" - ") else { return nil }
        
        let parts = title.components(separatedBy: " - ")
        guard parts.count >= 2 else { return nil }
        
        let extractedArtist = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let extractedTitle = parts.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespacesAndNewlines)
        
        return (artist: extractedArtist, title: extractedTitle)
    }
    
    /// Removes the artist name if it is duplicated at the start of the title
    private static func stripDuplicateArtistPrefix(artist: String, title: String) -> String {
        guard !artist.isEmpty else { return title }
        
        var currentTitle = title
        
        while currentTitle.localizedCaseInsensitiveContains(artist), currentTitle.lowercased().hasPrefix(artist.lowercased()) {
            currentTitle = String(currentTitle.dropFirst(artist.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Trim stray delimiters left behind after stripping the artist
            if currentTitle.hasPrefix("-") || currentTitle.hasPrefix(":") {
                currentTitle = String(currentTitle.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return currentTitle
    }
    
    /// Strips junk strings like (Official Video) or [Lyrics]
    private static func stripJunkTags(from title: String) -> String {
        let cleanTitle = title.replacingOccurrences(
            of: "\(bracketedJunkRegex)|\(trailingJunkRegex)",
            with: "",
            options: .regularExpression
        )
        return cleanTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Strips leading and trailing quotes if the title is fully quoted
    private static func stripSurroundingQuotes(from title: String) -> String {
        if title.hasPrefix("\"") && title.hasSuffix("\"") && title.count >= 2 {
            return String(title.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return title
    }
}
