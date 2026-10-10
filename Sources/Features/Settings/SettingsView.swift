import SwiftUI
import AppKit

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

enum SettingsTab: String, CaseIterable, Identifiable {
    case appearance = "Appearance"
    case translation = "Translation"
    case about = "About"
    
    var id: String { rawValue }
}

struct SettingsView: View {
    @ObservedObject var settings = UserPreferences.shared
    @State private var selectedTab: SettingsTab = .appearance
    
    var body: some View {
        ZStack(alignment: .top) {
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top header bar with traffic lights reservation and centered segmented tabs
                HStack {
                    Spacer()
                        .frame(width: 70)
                    
                    Spacer()
                    
                    HStack(spacing: 0) {
                        ForEach(SettingsTab.allCases) { tab in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedTab = tab
                                }
                            } label: {
                                Text(tab.rawValue)
                                    .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                                    .foregroundColor(selectedTab == tab ? .primary : .secondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                            .fill(selectedTab == tab ? Color.white.opacity(0.18) : Color.clear)
                                    )
                                    .contentShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(2)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.black.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
                    
                    Spacer()
                    
                    Spacer()
                        .frame(width: 70)
                }
                .frame(height: 50)
                .padding(.top, 4)
                
                Divider()
                    .opacity(0.2)
                
                // Tab Content
                Group {
                    switch selectedTab {
                    case .appearance:
                        AppearanceTab(settings: settings)
                    case .translation:
                        TranslationTab(settings: settings)
                    case .about:
                        AboutTab(settings: settings)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 480, height: 530)
    }
}
