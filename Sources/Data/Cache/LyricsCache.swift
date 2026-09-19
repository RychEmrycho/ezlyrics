import Foundation

actor LyricsCache: LyricsCacheProtocol {
    
    private let memoryCache = NSCache<NSString, NSData>()
    
    let cacheDirectory: URL?
    
    init(cacheDirectory: URL? = nil) {
        if let dir = cacheDirectory {
            self.cacheDirectory = dir
        } else {
            if let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                self.cacheDirectory = supportDir.appendingPathComponent("ezlyrics").appendingPathComponent("Lyrics")
            } else {
                self.cacheDirectory = nil
            }
        }
        
        if let dir = self.cacheDirectory {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    private func cacheKey(artist: String, title: String) -> String {
        let cleanArtist = artist.lowercased().replacingOccurrences(of: " ", with: "")
        let cleanTitle = title.lowercased().replacingOccurrences(of: " ", with: "")
        // hash or encode for safe filenames
        return "\(cleanArtist.hashValue)_\(cleanTitle.hashValue)"
    }
    
    func getCachedLyrics(artist: String, title: String) -> ParsedLyrics? {
        let key = cacheKey(artist: artist, title: title)
        let nsKey = NSString(string: key)
        
        // Tier 1: Memory
        if let data = memoryCache.object(forKey: nsKey),
           let lyrics = try? JSONDecoder().decode(ParsedLyrics.self, from: data as Data) {
            return lyrics
        }
        
        // Tier 2: Disk
        guard let dir = cacheDirectory else { return nil }
        let fileURL = dir.appendingPathComponent("\(key).json")
        if let data = try? Data(contentsOf: fileURL),
           let lyrics = try? JSONDecoder().decode(ParsedLyrics.self, from: data) {
            
            // Populate memory cache
            memoryCache.setObject(data as NSData, forKey: nsKey)
            return lyrics
        }
        
        return nil
    }
    
    func cache(lyrics: ParsedLyrics, artist: String, title: String) {
        let key = cacheKey(artist: artist, title: title)
        let nsKey = NSString(string: key)
        
        guard let data = try? JSONEncoder().encode(lyrics) else { return }
        
        // Tier 1: Memory
        memoryCache.setObject(data as NSData, forKey: nsKey)
        
        // Tier 2: Disk
        guard let dir = cacheDirectory else { return }
        let fileURL = dir.appendingPathComponent("\(key).json")
        try? data.write(to: fileURL)
    }
}
