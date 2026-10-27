import SwiftUI

/// Tela Menu do aluno: centraliza o acesso às funcionalidades que antes ficavam no rodapé.
///
/// Reutiliza as telas existentes — a navegação é feita pelo `StudentRootView`
/// (seleção de seção ou push na pilha própria do Menu).
struct StudentMenuView: View {

    @Binding var path: [AppRoute]
    let onBack: () -> Void
    let onSelectSection: (StudentMainSection) -> Void
    /// Abre diretamente Anotações, Lembretes ou Aniversários.
    let onOpenOrganizer: (PersonalOrganizerSection) -> Void

    /// Treinos só existe para alunos com professor vinculado (regra já existente do rodapé).
    @Environment(\.studentShowsWorkoutsTab) private var showsWorkouts

    var body: some View {
        PersonalScreenScaffold(
            titleKey: "menu.title",
            onBack: onBack,
            onSelectSection: onSelectSection
        ) {
            category("menu.category.training") {
                menuRow(icon: "trophy.fill", titleKey: "menu.personal_records") {
                    onSelectSection(.records)
                }
                menuRow(icon: "dumbbell.fill", titleKey: "menu.wod") {
                    path.append(.studentNextFitWod)
                }
                if showsWorkouts {
                    menuRow(icon: "figure.strengthtraining.traditional", titleKey: "menu.workouts") {
                        onSelectSection(.agenda)
                    }
                }
            }

            category("menu.category.personal") {
                menuRow(icon: "calendar.badge.clock", titleKey: "menu.my_routine") {
                    onOpenOrganizer(.notes)
                }
            }

            category("menu.category.explore") {
                menuRow(icon: "magnifyingglass", titleKey: "menu.athletes") {
                    path.append(.studentComingSoon(titleKey: "menu.search_athletes"))
                }
                menuRow(icon: "trophy", titleKey: "menu.championships") {
                    path.append(.studentComingSoon(titleKey: "menu.search_championships"))
                }
            }
        }
    }

    private func category<Rows: View>(
        _ titleKey: LocalizedStringKey,
        @ViewBuilder rows: () -> Rows
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titleKey)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink(0.55))
                .padding(.horizontal, 6)

            rows()
        }
    }

    private func menuRow(
        icon: String,
        titleKey: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                PersonalRowIcon(systemName: icon)

                Text(titleKey)
                    .font(.system(size: 17, weight: .semibold))
                    .modifier(PersonalPrimaryTextStyle())
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .foregroundStyle(
                        AppThemeColor(
                            dark: Color.white.opacity(0.35),
                            light: PersonalOrganizerLightColors.chevron
                        )
                    )
            }
            .modifier(StudentMenuCardModifier())
        }
        .buttonStyle(.plain)
    }
}

/// Igual a `PersonalCardModifier`, alterando somente o fundo do Tema Claro (#DDEDDC).
private struct StudentMenuCardModifier: ViewModifier {
    @Environment(\.appTheme) private var appTheme

    private static let lightSurface = Color(
        red: 0xDD / 255,
        green: 0xED / 255,
        blue: 0xDC / 255
    )

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppThemeColor(dark: Color.black.opacity(0.68), light: Self.lightSurface))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        AppThemeColor(
                            dark: Theme.Colors.primaryGreen.opacity(0.28),
                            light: PersonalOrganizerLightColors.chevron
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: appTheme == .light ? .black.opacity(0.25) : .clear,
                radius: appTheme == .light ? 10 : 0,
                y: appTheme == .light ? 6 : 0
            )
    }
}

