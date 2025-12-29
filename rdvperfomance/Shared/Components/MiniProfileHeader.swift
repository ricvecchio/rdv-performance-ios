import SwiftUI

/// Mini header do perfil: SOMENTE a foto redonda.
/// ✅ Sem marcação/anel
/// ✅ Sem fundo
/// ✅ Sem zoom
struct MiniProfileHeader: View {

    let imageName: String
    var size: CGFloat = 38

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .clipped()
            .frame(width: size, height: size)
            .contentShape(Circle())
            .accessibilityLabel("Perfil")
    }
}

