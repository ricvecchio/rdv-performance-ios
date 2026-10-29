import SwiftUI

/// Tela mínima para funcionalidades do Menu ainda não disponíveis (somente título e mensagem).
struct StudentComingSoonView: View {
    @Binding var path: [AppRoute]
    let titleKey: String
    let onSelectSection: (StudentMainSection) -> Void

    var body: some View {
        PersonalScreenScaffold(
            titleKey: LocalizedStringKey(titleKey),
            onBack: {
                if !path.isEmpty { path.removeLast() }
            },
            onSelectSection: onSelectSection
        ) {
            Text("menu.coming_soon")
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.ink(0.55))
                .personalCard()
        }
    }
}

