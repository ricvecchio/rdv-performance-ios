// MiniProfileHeader.swift — Componente simples para exibir imagem de perfil circular
import SwiftUI

struct MiniProfileHeader: View {

    let imageName: String
    var size: CGFloat = 38

    // Imagem circular sem decoração adicional
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
