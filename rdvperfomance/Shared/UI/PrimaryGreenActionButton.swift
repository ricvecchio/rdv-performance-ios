import SwiftUI

private struct PrimaryGreenActionButtonModifier: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(isEnabled ? .white.opacity(0.92) : .white.opacity(0.55))
            .padding(.vertical, 14)
            .background(
                isEnabled
                    ? Theme.Colors.primaryGreen.opacity(0.18)
                    : Color.white.opacity(0.10)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isEnabled
                            ? Theme.Colors.primaryGreen.opacity(0.30)
                            : Color.white.opacity(0.12),
                        lineWidth: 1
                    )
            )
    }
}

private struct CompactPrimaryGreenActionButtonModifier: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(isEnabled ? .white.opacity(0.92) : .white.opacity(0.55))
            .padding(.vertical, 9)
            .background(
                isEnabled
                    ? Theme.Colors.primaryGreen.opacity(0.18)
                    : Color.white.opacity(0.10)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isEnabled
                            ? Theme.Colors.primaryGreen.opacity(0.30)
                            : Color.white.opacity(0.12),
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    func primaryGreenActionButton() -> some View {
        modifier(PrimaryGreenActionButtonModifier())
    }

    func compactPrimaryGreenActionButton() -> some View {
        modifier(CompactPrimaryGreenActionButtonModifier())
    }
}
