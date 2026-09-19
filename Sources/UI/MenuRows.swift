import SwiftUI

struct MenuItemRow: View {
    let title: String
    let iconName: String
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: iconName)
                    .frame(width: 16, alignment: .center)
                Text(title)
            }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(isHovered ? Color.accentColor : Color.clear)
                .foregroundColor(isHovered ? .white : .primary)
                .cornerRadius(4)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

struct MenuToggleRow: View {
    let title: String
    let iconName: String
    @Binding var isOn: Bool
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .frame(width: 16, alignment: .center)
            Text(title)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .scaleEffect(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isHovered ? Color.accentColor : Color.clear)
        .foregroundColor(isHovered ? .white : .primary)
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onTapGesture {
            isOn.toggle()
        }
        .onHover { isHovered = $0 }
    }
}
