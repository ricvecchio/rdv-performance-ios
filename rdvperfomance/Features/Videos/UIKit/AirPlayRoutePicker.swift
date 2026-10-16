import SwiftUI
import AVKit

struct AirPlayRoutePicker: UIViewRepresentable {
    
    func makeUIView(context: Context) -> AVRoutePickerView {
        let v = AVRoutePickerView(frame: .zero)
        v.prioritizesVideoDevices = true
        v.activeTintColor = UIColor.systemGreen
        v.tintColor = Self.tintColor(for: context.environment.appTheme)
        return v
    }
    
    // Atualiza apenas a cor do ícone quando o tema muda (sem recriar o componente)
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        let tintColor = Self.tintColor(for: context.environment.appTheme)
        if uiView.tintColor != tintColor {
            uiView.tintColor = tintColor
        }
    }

    // Escuro: cor original. Claro: mesma "tinta" dos textos do Tema Claro (legível sobre o cabeçalho claro)
    private static func tintColor(for theme: AppTheme) -> UIColor {
        switch theme {
        case .dark:
            UIColor.white.withAlphaComponent(0.90)
        case .light:
            UIColor(AppThemePalette.lightInk.opacity(AppThemePalette.lightOpacity(for: 0.90)))
        }
    }
}
