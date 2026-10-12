import SwiftUI
import AVKit

struct AirPlayRoutePicker: UIViewRepresentable {
    
    func makeUIView(context: Context) -> AVRoutePickerView {
        let v = AVRoutePickerView(frame: .zero)
        v.prioritizesVideoDevices = true
        v.activeTintColor = UIColor.systemGreen
        v.tintColor = UIColor.white.withAlphaComponent(0.90)
        return v
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) { }
}
