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
                if showsWorkouts {
                    menuRow(icon: "figure.strengthtraining.traditional", titleKey: "menu.workouts") {
                        onSelectSection(.agenda)
                    }
                }
                menuRow(icon: "trophy.fill", titleKey: "menu.personal_records") {
                    onSelectSection(.records)
                }
                menuRow(icon: "chart.line.uptrend.xyaxis", titleKey: "menu.progress") {
                    path.append(.studentComingSoon(titleKey: "menu.progress"))
                }
                menuRow(icon: "dumbbell.fill", titleKey: "menu.wod") {
                    path.append(.studentNextFitWod)
                }
            }

            category("menu.category.personal") {
                menuRow(icon: "note.text", titleKey: "menu.notes") {
                    onOpenOrganizer(.notes)
                }
                menuRow(icon: "bell", titleKey: "menu.reminders") {
                    onOpenOrganizer(.reminders)
                }
                menuRow(icon: "gift", titleKey: "menu.birthdays") {
                    onOpenOrganizer(.birthdays)
                }
            }

            category("menu.category.explore") {
                menuRow(icon: "magnifyingglass", titleKey: "menu.search_athletes") {
                    path.append(.studentComingSoon(titleKey: "menu.search_athletes"))
                }
                menuRow(icon: "trophy", titleKey: "menu.search_championships") {
                    path.append(.studentComingSoon(titleKey: "menu.search_championships"))
                }
            }

            category("menu.category.account") {
                menuRow(icon: "person", titleKey: "menu.my_profile") {
                    onSelectSection(.profile)
                }
                menuRow(icon: "gearshape", titleKey: "menu.settings") {
                    path.append(.configuracoes)
                }
                menuRow(icon: "questionmark.circle", titleKey: "menu.help_support") {
                    path.append(.infoLegal(.helpCenter))
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
            .personalCard()
        }
        .buttonStyle(.plain)
    }
}

