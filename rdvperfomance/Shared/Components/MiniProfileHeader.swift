// Componente para exibir imagem de perfil em formato circular
import SwiftUI

// View simples que exibe uma imagem redonda
struct MiniProfileHeader: View {

    let imageName: String
    var size: CGFloat = 38

    // Retorna a imagem em formato circular
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
