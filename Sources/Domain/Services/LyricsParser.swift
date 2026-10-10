import Foundation
import NaturalLanguage

/// Parses raw lyrics strings (LRC synced format and plain text) into domain models.
struct LyricsParser {
    
    static func parse(plain: String?, synced: String?, trackName: String, artistName: String, sourceID: Int? = nil) -> ParsedLyrics {
        var lines: [LyricLine] = []
        var isSynced = false
        
        if let synced = synced, !synced.isEmpty {
            lines = parseSynced(lrc: synced)
            isSynced = true
        } else if let plain = plain, !plain.isEmpty {
            lines = plain.components(separatedBy: .newlines).map {
                LyricLine(timestamp: 0, text: $0, syllables: nil)
            }
            isSynced = false
        }
        
        var detectedLanguage: String?
        let sampleText = lines.prefix(20).map { $0.text }.joined(separator: " ")
        if !sampleText.isEmpty {
            let recognizer = NLLanguageRecognizer()
            recognizer.processString(sampleText)
            detectedLanguage = recognizer.dominantLanguage?.rawValue
        }
        
        return ParsedLyrics(trackName: trackName, artistName: artistName, isSynced: isSynced, lines: lines, detectedLanguage: detectedLanguage, sourceID: sourceID)
    }
    
    private static func parseSynced(lrc: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        
        // Parse optional [offset: +/-ms] tag (positive = delay playback, negative = advance)
        var globalOffset: TimeInterval = 0
        let offsetPattern = "\\[offset:\\s*([+-]?\\d+)\\]"
        if let offsetRegex = try? NSRegularExpression(pattern: offsetPattern, options: .caseInsensitive),
           let offsetMatch = offsetRegex.firstMatch(in: lrc, options: [], range: NSRange(location: 0, length: (lrc as NSString).length)) {
            let offsetStr = (lrc as NSString).substring(with: offsetMatch.range(at: 1))
            if let offsetMs = Double(offsetStr) {
                globalOffset = offsetMs / 1000.0
            }
        }
        
        // Regex to match leading line timestamp [mm:ss.xx] or [m:ss.xxx]
        let tagPattern = "^\\[(\\d{1,2}):(\\d{2}(?:\\.\\d{1,3})?)\\]"
        // Regex to match syllable timestamp <mm:ss.xx>
        let syllablePattern = "<(\\d{1,2}):(\\d{2}(?:\\.\\d{1,3})?)>([^<]*)"
        
        guard let tagRegex = try? NSRegularExpression(pattern: tagPattern, options: []),
              let syllableRegex = try? NSRegularExpression(pattern: syllablePattern, options: []) else { return [] }
        
        let rawStrings = lrc.components(separatedBy: .newlines)
        for rawString in rawStrings {
            var remaining = rawString.trimmingCharacters(in: .whitespaces)
            var timestamps: [TimeInterval] = []
            
            // Extract all leading timestamp tags (handles single [mm:ss.xx] as well as multiple [mm:ss.xx][mm:ss.yy])
            while let match = tagRegex.firstMatch(in: remaining, options: [], range: NSRange(location: 0, length: (remaining as NSString).length)) {
                let ns = remaining as NSString
                let minuteStr = ns.substring(with: match.range(at: 1))
                let secondStr = ns.substring(with: match.range(at: 2))
                if let minute = Double(minuteStr), let second = Double(secondStr) {
                    timestamps.append((minute * 60) + second + globalOffset)
                }
                remaining = ns.substring(from: match.range.location + match.range.length).trimmingCharacters(in: .whitespaces)
            }
            
            guard !timestamps.isEmpty else { continue }
            
            // Parse syllables if present in the text
            var syllables: [Syllable] = []
            let textNs = remaining as NSString
            let syllableMatches = syllableRegex.matches(in: remaining, options: [], range: NSRange(location: 0, length: textNs.length))
            
            for sylMatch in syllableMatches where sylMatch.numberOfRanges == 4 {
                let sMin = textNs.substring(with: sylMatch.range(at: 1))
                let sSec = textNs.substring(with: sylMatch.range(at: 2))
                let sText = textNs.substring(with: sylMatch.range(at: 3))
                
                if let sm = Double(sMin), let ss = Double(sSec) {
                    let sTimestamp = (sm * 60) + ss + globalOffset
                    syllables.append(Syllable(timestamp: sTimestamp, text: sText))
                }
            }
            
            let cleanText = remaining.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression).trimmingCharacters(in: .whitespaces)
            let syllablesToUse = syllables.isEmpty ? nil : syllables
            
            for ts in timestamps {
                lines.append(LyricLine(timestamp: max(0, ts), text: cleanText, syllables: syllablesToUse))
            }
        }
        
        return lines.sorted { $0.timestamp < $1.timestamp }
    }
}
