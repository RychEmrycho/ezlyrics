import SwiftUI

struct PillBadgeModifier: ViewModifier {
    let color: Color
    let textColor: Color
    let isEnabled: Bool
    
    func body(content: Content) -> some View {
        if isEnabled {
            content
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color)
                .foregroundColor(textColor)
                .clipShape(Capsule())
        } else {
            content
        }
    }
}

extension View {
    func pillBadge(color: Color, textColor: Color = .white, isEnabled: Bool = true) -> some View {
        self.modifier(PillBadgeModifier(color: color, textColor: textColor, isEnabled: isEnabled))
    }
}
