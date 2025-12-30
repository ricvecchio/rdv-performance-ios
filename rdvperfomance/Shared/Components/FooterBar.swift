import SwiftUI

// MARK: - FooterBar
struct FooterBar: View {

    enum Kind {

        // ====== BÁSICOS ======
        case homeSobre(isHomeSelected: Bool, isSobreSelected: Bool)

        case homeSobrePerfil(
            isHomeSelected: Bool,
            isSobreSelected: Bool,
            isPerfilSelected: Bool
        )

        case treinos(
            treinoTitle: String,
            treinoIcon: AnyView,
            isHomeSelected: Bool,
            isTreinoSelected: Bool,
            isSobreSelected: Bool
        )

        case treinosComPerfil(
            treinoTitle: String,
            treinoIcon: AnyView,
            isHomeSelected: Bool,
            isTreinoSelected: Bool,
            isSobreSelected: Bool,
            isPerfilSelected: Bool
        )

        // ====== ALUNO ======
        case agendaSobrePerfil(
            isAgendaSelected: Bool,
            isSobreSelected: Bool,
            isPerfilSelected: Bool
        )

        case agendaTreinosSobrePerfil(
            isAgendaSelected: Bool,
            isTreinosSelected: Bool,
            isSobreSelected: Bool,
            isPerfilSelected: Bool
        )

        // ====== PROFESSOR ======
        /// ✅ Professor: Home | Alunos | Sobre | Perfil
        case teacherHomeAlunosSobrePerfil(
            selectedCategory: TreinoTipo,
            isHomeSelected: Bool,
            isAlunosSelected: Bool,
            isSobreSelected: Bool,
            isPerfilSelected: Bool
        )

        /// ✅ NOVO: Professor: Home | Aluno | Sobre | Perfil (singular) — usado na tela expandida
        case teacherHomeAlunoSobrePerfil(
            selectedCategory: TreinoTipo,
            isHomeSelected: Bool,
            isAlunoSelected: Bool,
            isSobreSelected: Bool,
            isPerfilSelected: Bool
        )
    }

    @Binding var path: [AppRoute]
    let kind: Kind

    var body: some View {
        VStack(spacing: 0) {

            Rectangle()
                .fill(Theme.Colors.divider)
                .frame(height: 1)
                .frame(maxWidth: .infinity)

            contentRow()
                .padding(.top, 8)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.Colors.footerBackground)
    }

    // MARK: - Conteúdo do rodapé
    @ViewBuilder
    private func contentRow() -> some View {
        switch kind {

        // ====== BÁSICOS ======
        case .homeSobre(let isHomeSelected, let isSobreSelected):
            HStack(spacing: 28) {
                Button { goHomeBasic() } label: {
                    FooterItem(icon: .system("house"), title: "Home", isSelected: isHomeSelected, width: Theme.Layout.footerItemWidthHomeSobre)
                }
                .buttonStyle(.plain)

                Color.clear
                    .frame(width: Theme.Layout.footerMiddleSpacerWidth, height: 1)

                Button { goSobreBasic() } label: {
                    FooterItem(icon: .system("bubble.left"), title: "Sobre", isSelected: isSobreSelected, width: Theme.Layout.footerItemWidthHomeSobre)
                }
                .buttonStyle(.plain)
            }

        case .homeSobrePerfil(let isHomeSelected, let isSobreSelected, let isPerfilSelected):
            HStack(spacing: 26) {
                Button { goHomeBasic() } label: {
                    FooterItem(icon: .system("house"), title: "Home", isSelected: isHomeSelected, width: Theme.Layout.footerItemWidthHomeSobrePerfil)
                }
                .buttonStyle(.plain)

                Button { goSobreBasic() } label: {
                    FooterItem(icon: .system("bubble.left"), title: "Sobre", isSelected: isSobreSelected, width: Theme.Layout.footerItemWidthHomeSobrePerfil)
                }
                .buttonStyle(.plain)

                Button { goPerfilBasic() } label: {
                    FooterItem(icon: .system("person"), title: "Perfil", isSelected: isPerfilSelected, width: Theme.Layout.footerItemWidthHomeSobrePerfil)
                }
                .buttonStyle(.plain)
            }

        case .treinos(let treinoTitle, let treinoIcon, let isHomeSelected, let isTreinoSelected, let isSobreSelected):
            HStack(spacing: 28) {
                Button { goHomeBasic() } label: {
                    FooterItem(icon: .system("house"), title: "Home", isSelected: isHomeSelected, width: Theme.Layout.footerItemWidthTreinos)
                }
                .buttonStyle(.plain)

                FooterItem(icon: .custom(treinoIcon), title: treinoTitle, isSelected: isTreinoSelected, width: Theme.Layout.footerItemWidthTreinos)

                Button { goSobreBasic() } label: {
                    FooterItem(icon: .system("bubble.left"), title: "Sobre", isSelected: isSobreSelected, width: Theme.Layout.footerItemWidthTreinos)
                }
                .buttonStyle(.plain)
            }

        case .treinosComPerfil(let treinoTitle, let treinoIcon, let isHomeSelected, let isTreinoSelected, let isSobreSelected, let isPerfilSelected):
            HStack(spacing: 16) {
                Button { goHomeBasic() } label: {
                    FooterItem(icon: .system("house"), title: "Home", isSelected: isHomeSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)

                FooterItem(icon: .custom(treinoIcon), title: treinoTitle, isSelected: isTreinoSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)

                Button { goSobreBasic() } label: {
                    FooterItem(icon: .system("bubble.left"), title: "Sobre", isSelected: isSobreSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)

                Button { goPerfilBasic() } label: {
                    FooterItem(icon: .system("person"), title: "Perfil", isSelected: isPerfilSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)
            }

        // ====== ALUNO ======
        case .agendaSobrePerfil(let isAgendaSelected, let isSobreSelected, let isPerfilSelected):
            HStack(spacing: 26) {
                Button { goAgenda() } label: {
                    FooterItem(icon: .system("calendar"), title: "Agenda", isSelected: isAgendaSelected, width: Theme.Layout.footerItemWidthHomeSobrePerfil)
                }
                .buttonStyle(.plain)

                Button { goSobreStudent() } label: {
                    FooterItem(icon: .system("bubble.left"), title: "Sobre", isSelected: isSobreSelected, width: Theme.Layout.footerItemWidthHomeSobrePerfil)
                }
                .buttonStyle(.plain)

                Button { goPerfilStudent() } label: {
                    FooterItem(icon: .system("person"), title: "Perfil", isSelected: isPerfilSelected, width: Theme.Layout.footerItemWidthHomeSobrePerfil)
                }
                .buttonStyle(.plain)
            }

        case .agendaTreinosSobrePerfil(let isAgendaSelected, let isTreinosSelected, let isSobreSelected, let isPerfilSelected):
            HStack(spacing: 12) {

                Button { goAgenda() } label: {
                    FooterItem(icon: .system("calendar"), title: "Agenda", isSelected: isAgendaSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)

                Button { goTreinosAluno() } label: {
                    FooterItem(icon: .system("figure.strengthtraining.traditional"), title: "Treinos", isSelected: isTreinosSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)

                Button { goSobreStudent() } label: {
                    FooterItem(icon: .system("bubble.left"), title: "Sobre", isSelected: isSobreSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)

                Button { goPerfilStudent() } label: {
                    FooterItem(icon: .system("person"), title: "Perfil", isSelected: isPerfilSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)
            }

        // ====== PROFESSOR (plural) ======
        case .teacherHomeAlunosSobrePerfil(let selectedCategory, let isHomeSelected, let isAlunosSelected, let isSobreSelected, let isPerfilSelected):
            HStack(spacing: 12) {

                Button { goTeacherHome() } label: {
                    FooterItem(icon: .system("house"), title: "Home", isSelected: isHomeSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)

                Button { goTeacherAlunos(category: selectedCategory) } label: {
                    FooterItem(icon: .system("person.3"), title: "Alunos", isSelected: isAlunosSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)

                Button { goTeacherSobre(category: selectedCategory) } label: {
                    FooterItem(icon: .system("bubble.left"), title: "Sobre", isSelected: isSobreSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)

                Button { goTeacherPerfil(category: selectedCategory) } label: {
                    FooterItem(icon: .system("person"), title: "Perfil", isSelected: isPerfilSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)
            }

        // ====== PROFESSOR (singular) ======
        case .teacherHomeAlunoSobrePerfil(let selectedCategory, let isHomeSelected, let isAlunoSelected, let isSobreSelected, let isPerfilSelected):
            HStack(spacing: 12) {

                Button { goTeacherHome() } label: {
                    FooterItem(icon: .system("house"), title: "Home", isSelected: isHomeSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)

                // ✅ ÍCONE 1 PESSOA + TEXTO "Aluno"
                Button { goTeacherAlunos(category: selectedCategory) } label: {
                    FooterItem(icon: .system("person"), title: "Aluno", isSelected: isAlunoSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)

                Button { goTeacherSobre(category: selectedCategory) } label: {
                    FooterItem(icon: .system("bubble.left"), title: "Sobre", isSelected: isSobreSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)

                Button { goTeacherPerfil(category: selectedCategory) } label: {
                    FooterItem(icon: .system("person.fill"), title: "Perfil", isSelected: isPerfilSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Navegação Básica
    private func canonicalStackBasic(for destination: AppRoute) -> [AppRoute] {
        switch destination {
        case .home:  return [.home]
        case .sobre: return [.home, .sobre]
        case .perfil: return [.home, .sobre, .perfil]
        default:     return [.home]
        }
    }

    private func goHomeBasic()  { withAnimation { path = canonicalStackBasic(for: .home) } }
    private func goSobreBasic() { withAnimation { path = canonicalStackBasic(for: .sobre) } }
    private func goPerfilBasic(){ withAnimation { path = canonicalStackBasic(for: .perfil) } }

    // MARK: - Navegação Aluno
    private func goAgenda() { withAnimation { path = [.studentAgenda] } }
    private func goTreinosAluno() { withAnimation { path = [.studentAgenda] } }
    private func goSobreStudent() { withAnimation { path = [.studentAgenda, .sobre] } }
    private func goPerfilStudent() { withAnimation { path = [.studentAgenda, .sobre, .perfil] } }

    // MARK: - Navegação Professor
    private enum TeacherDestination { case home, alunos, sobre, perfil }

    private func teacherCanonicalStack(category: TreinoTipo, destination: TeacherDestination) -> [AppRoute] {
        switch destination {
        case .home:
            return [.home]
        case .alunos:
            return [.home, .teacherStudentsList(category)]
        case .sobre:
            return [.home, .teacherStudentsList(category), .sobre]
        case .perfil:
            return [.home, .teacherStudentsList(category), .sobre, .perfil]
        }
    }

    private func goTeacherHome() {
        withAnimation { path = teacherCanonicalStack(category: .crossfit, destination: .home) }
    }

    private func goTeacherAlunos(category: TreinoTipo) {
        withAnimation { path = teacherCanonicalStack(category: category, destination: .alunos) }
    }

    private func goTeacherSobre(category: TreinoTipo) {
        withAnimation { path = teacherCanonicalStack(category: category, destination: .sobre) }
    }

    private func goTeacherPerfil(category: TreinoTipo) {
        withAnimation { path = teacherCanonicalStack(category: category, destination: .perfil) }
    }
}

// MARK: - FooterItem (internal)
private struct FooterItem: View {

    enum Icon {
        case system(String)
        case custom(AnyView)
    }

    let icon: Icon
    let title: String
    let isSelected: Bool
    let width: CGFloat

    var body: some View {
        VStack(spacing: 6) {
            switch icon {
            case .system(let name):
                Image(systemName: name)
                    .font(Theme.Fonts.footerIcon())
            case .custom(let view):
                view
            }

            Text(title)
                .font(Theme.Fonts.footerTitle())
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundColor(isSelected ? Theme.Colors.selected : Theme.Colors.unselected)
        .frame(width: width)
    }
}

