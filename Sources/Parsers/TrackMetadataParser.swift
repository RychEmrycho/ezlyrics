import Foundation

/// Stateless parser that normalizes raw media metadata (artist/title strings)
/// into clean, search-friendly values. Handles platform quirks like YouTube
/// title formats, Japanese bracket conventions, and junk tags.
struct TrackMetadataParser {
    
    /// Takes raw artist/title strings from the media system
    /// and returns cleaned, normalized values.
    static func parse(rawArtist: String, rawTitle: String) -> (artist: String, title: String) {
        var artist = rawArtist
        var title = rawTitle
        
        // Japanese YouTube parsing: e.g. "KANA-BOON 『ないものねだり』Music Video"
        let jpRegex = try? NSRegularExpression(pattern: "『(.*?)』|「(.*?)」")
        if let regex = jpRegex, let match = regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)) {
            let fullMatchRange = Range(match.range, in: title)!
            let prefixStr = title[..<fullMatchRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let range1 = Range(match.range(at: 1), in: title) {
                title = String(title[range1])
            } else if let range2 = Range(match.range(at: 2), in: title) {
                title = String(title[range2])
            }
            
            if !prefixStr.isEmpty {
                artist = prefixStr
            }
        } else if title.contains(" - ") {
            let titleParts = title.components(separatedBy: " - ")
            if titleParts.count >= 2 {
                let firstPart = titleParts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let secondPart = titleParts.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Always use the title split as the source of truth for Artist and Title when available
                // Because YouTube channel names are often networks or have "VEVO" appended
                artist = firstPart
                title = secondPart
            }
        }
        
        // Strip junk tags that ruin lyrics searches like (Lyrics), [Official Music Video], etc.
        let cleanTitle = title.replacingOccurrences(of: "(?i)\\s*\\(.*?official.*?\\)|\\s*\\[.*?official.*?\\]|\\s*\\(.*?lyrics.*?\\)|\\s*\\[.*?lyrics.*?\\]", with: "", options: .regularExpression)
        title = cleanTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return (artist: artist, title: title)
    }
}
