import SwiftUI

struct TreeLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Floating leaves animation
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(leafColor(for: index))
                        .frame(width: 6, height: 6)
                        .offset(x: leafXOffset(for: index), y: isAnimating ? -30 : 0)
                        .opacity(isAnimating ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.3),
                            value: isAnimating
                        )
                }

                // Pulsing tree icon
                Image(systemName: "tree.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green.gradient)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            .frame(height: 60)

            Text("Growing worktree...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .onAppear { isAnimating = true }
    }

    private func leafColor(for index: Int) -> Color {
        let colors: [Color] = [.green, .mint, .green.opacity(0.7), .teal, .green.opacity(0.5)]
        return colors[index % colors.count]
    }

    private func leafXOffset(for index: Int) -> CGFloat {
        let offsets: [CGFloat] = [-12, -6, 0, 6, 12]
        return offsets[index % offsets.count]
    }
}
