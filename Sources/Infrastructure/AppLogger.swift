import Foundation
import os

struct AppLogger {
    static let shared = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ezlyrics", category: "main")
    static let mediaRemote = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ezlyrics", category: "mediaRemote")
    static let lyrics = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ezlyrics", category: "lyrics")
    static let ui = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ezlyrics", category: "ui")
}
