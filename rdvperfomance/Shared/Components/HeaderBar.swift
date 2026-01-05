// HeaderBar.swift — Componente de header reutilizável com separador inferior
import SwiftUI

struct HeaderBar<Content: View>: View {

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    // Layout do header com fundo do app e separador
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
