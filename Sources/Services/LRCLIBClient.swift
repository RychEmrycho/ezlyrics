import Foundation

class LRCLIBClient: @unchecked Sendable {
    static let shared = LRCLIBClient()
    
    private let baseURL = "https://lrclib.net/api"
    
    func getLyrics(artist: String, title: String, duration: TimeInterval, completion: @escaping @Sendable (LRCLIBResponse?) -> Void) {
        var components = URLComponents(string: "\(baseURL)/get")!
        var queryItems = [
            URLQueryItem(name: "artist_name", value: artist),
            URLQueryItem(name: "track_name", value: title)
        ]
        if duration > 0 {
            queryItems.append(URLQueryItem(name: "duration", value: String(Int(duration))))
        }
        components.queryItems = queryItems
        
        guard let url = components.url else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("ezlyrics/1.0 (https://github.com/emrycho/ezlyrics)", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                // If direct match fails, fallback to search
                self.searchLyrics(query: "\(artist) \(title)") { results in
                    completion(results?.first)
                }
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let result = try decoder.decode(LRCLIBResponse.self, from: data)
                completion(result)
            } catch {
                print("Failed to decode LRCLIB response: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    func searchLyrics(query: String, completion: @escaping @Sendable ([LRCLIBResponse]?) -> Void) {
        var components = URLComponents(string: "\(baseURL)/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query)
        ]
        
        guard let url = components.url else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("ezlyrics/1.0 (https://github.com/emrycho/ezlyrics)", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                // If it's not a 200 OK (e.g. 404 Not Found or 400 Bad Request), it won't be an array.
                completion(nil)
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let results = try decoder.decode([LRCLIBResponse].self, from: data)
                completion(results)
            } catch {
                // Only log actual decoding errors on 200 OK responses
                print("Failed to decode LRCLIB search response: \(error)")
                completion(nil)
            }
        }.resume()
    }
}
