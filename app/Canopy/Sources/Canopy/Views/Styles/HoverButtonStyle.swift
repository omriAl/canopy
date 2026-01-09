import SwiftUI

/// Button style with hover background highlight - ideal for icon buttons
struct HoverButtonStyle: ButtonStyle {
    @State private var isHovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isHovering ? Color.primary.opacity(0.1) : Color.clear)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

/// Button style for plain/text buttons with subtle hover effect
struct HoverPlainButtonStyle: ButtonStyle {
    @State private var isHovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(isHovering ? 0.7 : (configuration.isPressed ? 0.5 : 1.0))
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

/// Button style for menu items - full-width background highlight
struct HoverMenuButtonStyle: ButtonStyle {
    @State private var isHovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isHovering ? Color.primary.opacity(0.08) : Color.clear
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

extension ButtonStyle where Self == HoverButtonStyle {
    static var hover: HoverButtonStyle { HoverButtonStyle() }
}

extension ButtonStyle where Self == HoverPlainButtonStyle {
    static var hoverPlain: HoverPlainButtonStyle { HoverPlainButtonStyle() }
}

extension ButtonStyle where Self == HoverMenuButtonStyle {
    static var hoverMenu: HoverMenuButtonStyle { HoverMenuButtonStyle() }
}
