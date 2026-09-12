import Foundation

class LRCParser {
    
    static func parse(plain: String?, synced: String?, trackName: String, artistName: String) -> ParsedLyrics {
        if let synced = synced, !synced.isEmpty {
            let lines = parseSynced(lrc: synced)
            return ParsedLyrics(trackName: trackName, artistName: artistName, isSynced: true, lines: lines)
        } else if let plain = plain, !plain.isEmpty {
            let lines = plain.components(separatedBy: .newlines).map {
                LyricLine(timestamp: 0, text: $0, syllables: nil)
            }
            return ParsedLyrics(trackName: trackName, artistName: artistName, isSynced: false, lines: lines)
        } else {
            return ParsedLyrics(trackName: trackName, artistName: artistName, isSynced: false, lines: [])
        }
    }
    
    private static func parseSynced(lrc: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        
        // Regex to match line timestamp [mm:ss.xx]
        let pattern = "\\[(\\d{2}):(\\d{2}\\.\\d{2,3})\\](.*)"
        // Regex to match syllable timestamp <mm:ss.xx>
        let syllablePattern = "<(\\d{2}):(\\d{2}\\.\\d{2,3})>([^<]*)"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let syllableRegex = try? NSRegularExpression(pattern: syllablePattern, options: []) else { return [] }
        
        let strings = lrc.components(separatedBy: .newlines)
        for string in strings {
            let nsString = string as NSString
            let matches = regex.matches(in: string, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                if match.numberOfRanges == 4 {
                    let minuteStr = nsString.substring(with: match.range(at: 1))
                    let secondStr = nsString.substring(with: match.range(at: 2))
                    let text = nsString.substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespaces)
                    
                    if let minute = Double(minuteStr), let second = Double(secondStr) {
                        let timestamp = (minute * 60) + second
                        
                        // Parse syllables if present
                        var syllables: [Syllable] = []
                        let textNs = text as NSString
                        let syllableMatches = syllableRegex.matches(in: text, options: [], range: NSRange(location: 0, length: textNs.length))
                        
                        for sylMatch in syllableMatches {
                            if sylMatch.numberOfRanges == 4 {
                                let sMin = textNs.substring(with: sylMatch.range(at: 1))
                                let sSec = textNs.substring(with: sylMatch.range(at: 2))
                                let sText = textNs.substring(with: sylMatch.range(at: 3))
                                
                                if let sm = Double(sMin), let ss = Double(sSec) {
                                    let sTimestamp = (sm * 60) + ss
                                    syllables.append(Syllable(timestamp: sTimestamp, text: sText))
                                }
                            }
                        }
                        
                        let cleanText = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression).trimmingCharacters(in: .whitespaces)
                        
                        lines.append(LyricLine(timestamp: timestamp, text: cleanText, syllables: syllables.isEmpty ? nil : syllables))
                    }
                }
            }
        }
        
        return lines.sorted { $0.timestamp < $1.timestamp }
    }
}
