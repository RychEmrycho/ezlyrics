import SwiftUI
import AppKit

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 16) {
            if let icon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 80, height: 80)
            }
            
            VStack(spacing: 4) {
                Text("ezlyrics")
                    .font(.title)
                    .fontWeight(.bold)
                
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
                let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
                
                Text("Version \(version) (\(build))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("A lightweight menu bar lyrics application.")
                .multilineTextAlignment(.center)
                .font(.body)
                .padding(.horizontal)
            
            Text("Made with ❤️ by [Emrycho](https://www.linkedin.com/in/rychemrycho/)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
            Spacer()
                .frame(height: 10)
            
            Link("GitHub Repository", destination: URL(string: "https://github.com/RychEmrycho/ezlyrics")!)
                .font(.body)
            
            Link("Report an Issue", destination: URL(string: "https://github.com/RychEmrycho/ezlyrics/issues")!)
                .font(.body)
            
            Spacer()
        }
        .padding(40)
    }
}
