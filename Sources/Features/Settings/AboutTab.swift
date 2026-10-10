import SwiftUI
import AppKit

struct AboutTab: View {
    @ObservedObject var settings: UserPreferences
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let icon = NSImage(named: NSImage.applicationIconName) ?? NSApp.applicationIconImage {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 100, height: 100)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                }
                
                VStack(spacing: 8) {
                    Text("ezlyrics")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.2.0"
                    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
                    let versionText = (build != nil && !build!.isEmpty && build != "Unknown") ? "Version \(version) (\(build!))" : "Version \(version)"
                    
                    Text(versionText)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Capsule())
                }
                
                Text("A simple, floating lyrics widget for macOS.")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Text("Made with ❤️ by [Emrycho](https://github.com/RychEmrycho) and [contributors](https://github.com/RychEmrycho/ezlyrics/graphs/contributors)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Divider()
                    .padding(.horizontal, 32)
                    .padding(.vertical, 8)
                
                VStack(spacing: 12) {
                    Button {
                        Task {
                            await AppUpdateChecker.shared.checkForUpdates(silent: false)
                        }
                    } label: {
                        Text("Check for Updates...")
                            .frame(minWidth: 140)
                    }
                    .controlSize(.large)
                    
                    Toggle("Check for updates automatically", isOn: $settings.checkForUpdatesAutomatically)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                    .frame(height: 10)
                
                HStack(spacing: 16) {
                    Link(destination: URL(string: "https://github.com/RychEmrycho/ezlyrics")!) {
                        Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                            .frame(width: 120, height: 32)
                    }
                    .buttonStyle(.link)
                    
                    Link(destination: URL(string: "https://github.com/RychEmrycho/ezlyrics/issues")!) {
                        Label("Report Issue", systemImage: "ladybug")
                            .frame(width: 120, height: 32)
                    }
                    .buttonStyle(.link)
                }
                
                Spacer()
            }
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
        }
        .scrollContentBackground(.hidden)
    }
}
