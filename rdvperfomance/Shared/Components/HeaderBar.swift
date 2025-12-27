import SwiftUI

// MARK: - HeaderBar
// Componente reutilizável para cabeçalho com:
// ✅ Fundo padrão do app
// ✅ Conteúdo (título/botões) definido pela tela
// ✅ Linha separadora fixa na parte de baixo (divide Header / Corpo)
struct HeaderBar<Content: View>: View {

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {

            // Conteúdo do header (ex.: título + botões)
            content
                .frame(height: Theme.Layout.headerHeight)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.headerBackground)

            // ✅ Separador fixo colado na base do header
            Rectangle()
                .fill(Theme.Colors.divider)
                .frame(height: 1)
                .frame(maxWidth: .infinity)
        }
    }
}

