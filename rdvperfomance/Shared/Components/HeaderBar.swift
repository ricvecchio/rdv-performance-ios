// Componente de cabeçalho reutilizável com layout padronizado
import SwiftUI

// Container para o header com fundo e separador inferior
struct HeaderBar<Content: View>: View {

    let content: Content

    // Inicializa o header com conteúdo customizado
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    // Constrói o header com fundo e linha separadora
    var body: some View {
        VStack(spacing: 0) {

            content
                .frame(height: Theme.Layout.headerHeight)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.headerBackground)

            Rectangle()
                .fill(Theme.Colors.divider)
                .frame(height: 1)
                .frame(maxWidth: .infinity)
        }
    }
}
