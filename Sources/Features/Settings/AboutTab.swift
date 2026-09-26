import SwiftUI
import AppKit

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 20) {
            if let icon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            
            VStack(spacing: 8) {
                Text("ezlyrics")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
                let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
                
                Text("Version \(version) (\(build))")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }
            
            Text("A lightweight menu bar lyrics application.")
                .multilineTextAlignment(.center)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Text("Made with ❤️ by [Emrycho](https://www.linkedin.com/in/rychemrycho/)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
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
    }
}
