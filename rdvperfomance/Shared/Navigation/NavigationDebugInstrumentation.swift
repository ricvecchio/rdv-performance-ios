import SwiftUI
import Combine
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

final class NavigationHeaderDebugProbe: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()

    let name: String
    private var frame: CGRect = .zero

    init(name: String) {
        self.name = name
    }

    func recordFrame(_ frame: CGRect) {
        guard self.frame != frame else { return }
        self.frame = frame
        print(
            "[NAV][FRAME][\(name)]",
            CACurrentMediaTime(),
            "x:", frame.origin.x,
            "y:", frame.origin.y,
            "w:", frame.size.width,
            "h:", frame.size.height
        )
    }
}

struct NavigationHeaderProbeAttachment: View {
    @ObservedObject var probe: NavigationHeaderDebugProbe

    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .onAppear {
                    probe.recordFrame(geometry.frame(in: .global))
                }
                .onChange(of: geometry.frame(in: .global)) { _, frame in
                    probe.recordFrame(frame)
                }
        }
    }
}

#endif
