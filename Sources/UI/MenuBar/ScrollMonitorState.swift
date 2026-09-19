import SwiftUI
import AppKit

@MainActor
class ScrollMonitorState: ObservableObject {
    @Published var isAutoFollowing = true
    @Published var isHoveringLyrics = false
    private var scrollMonitor: Any?

    func startMonitoring() {
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self = self else { return event }
            if self.isAutoFollowing && self.isHoveringLyrics {
                DispatchQueue.main.async {
                    self.isAutoFollowing = false
                }
            }
            return event
        }
    }

    func stopMonitoring() {
        if let monitor = scrollMonitor {
            NSEvent.removeMonitor(monitor)
            scrollMonitor = nil
        }
    }
}
