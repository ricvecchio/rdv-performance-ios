import SwiftUI
import QuartzCore

#if DEBUG
struct NavigationDebugButtonStyle: ButtonStyle {
    let name: String

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                print("[NAV][TOUCH][\(name)]", CACurrentMediaTime(), "isPressed:", pressed)
            }
    }
}

#endif
