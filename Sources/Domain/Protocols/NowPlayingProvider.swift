import Foundation

/// Abstracts the system media monitoring layer.
/// Concrete implementations bridge to platform-specific APIs (e.g. MediaRemote on macOS).
@MainActor
protocol NowPlayingProvider: AnyObject {
    var onTrackChanged: ((Track?) -> Void)? { get set }
    func start()
    func stop()
}
