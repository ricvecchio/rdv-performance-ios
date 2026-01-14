import SwiftUI

// Barra de navegação inferior com diferentes configurações para cada tipo de usuário
struct FooterBar: View {

    // Define os diferentes tipos de footer disponíveis no app
    enum Kind {

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

        case teacherHomeAlunosSobrePerfil(
            selectedCategory: TreinoTipo,
            isHomeSelected: Bool,
            isAlunosSelected: Bool,
            isSobreSelected: Bool,
            isPerfilSelected: Bool
        )

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

    @EnvironmentObject private var session: AppSession

    // Constrói o footer com divider superior e botões de navegação
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

    // Retorna a configuração de botões apropriada baseado no Kind selecionado
    @ViewBuilder
    private func contentRow() -> some View {
        switch kind {
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

        case .teacherHomeAlunosSobrePerfil(let selectedCategory, let isHomeSelected, let isAlunosSelected, let isSobreSelected, let isPerfilSelected):
            HStack(spacing: 12) {

                Button { goTeacherHome(category: selectedCategory) } label: {
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

        case .teacherHomeAlunoSobrePerfil(let selectedCategory, let isHomeSelected, let isAlunoSelected, let isSobreSelected, let isPerfilSelected):
            HStack(spacing: 12) {

                Button { goTeacherHome(category: selectedCategory) } label: {
                    FooterItem(icon: .system("house"), title: "Home", isSelected: isHomeSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)

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

    // Retorna a pilha de navegação canônica para o destino especificado
    private func canonicalStackBasic(for destination: AppRoute) -> [AppRoute] {
        switch destination {
        case .home:  return [.home]
        case .sobre: return [.home, .sobre]
        case .perfil: return [.home, .sobre, .perfil]
        default:     return [.home]
        }
    }

    // Métodos de navegação básica sem animação
    private func goHomeBasic()   { path = canonicalStackBasic(for: .home) }
    private func goSobreBasic()  { path = canonicalStackBasic(for: .sobre) }
    private func goPerfilBasic() { path = canonicalStackBasic(for: .perfil) }

    // Navega para a agenda do aluno atual
    private func goAgenda() {
        guard let studentId = session.uid else { return }
        let studentName = session.userName ?? "Aluno"
        path = [.studentAgenda(studentId: studentId, studentName: studentName)]
    }

    // Navega para a seção de treinos do aluno
    private func goTreinosAluno() {
        guard let studentId = session.uid else { return }
        let studentName = session.userName ?? "Aluno"
        path = [.studentAgenda(studentId: studentId, studentName: studentName)]
    }

    // Navega para a tela Sobre do aluno
    private func goSobreStudent() {
        guard let studentId = session.uid else { return }
        let studentName = session.userName ?? "Aluno"
        path = [.studentAgenda(studentId: studentId, studentName: studentName), .sobre]
    }

    // Navega para o perfil do aluno
    private func goPerfilStudent() {
        guard let studentId = session.uid else { return }
        let studentName = session.userName ?? "Aluno"
        path = [.studentAgenda(studentId: studentId, studentName: studentName), .sobre, .perfil]
    }

    // Enum para identificar os destinos possíveis de navegação do professor
    private enum TeacherDestination { case home, alunos, sobre, perfil }

    // ✅ AJUSTE: pilha canônica do professor passa a começar no TeacherDashboardView
    private func teacherCanonicalStack(category: TreinoTipo, destination: TeacherDestination) -> [AppRoute] {
        switch destination {
        case .home:
            return [.teacherDashboard(category: category)]

        case .alunos:
            return [
                .teacherDashboard(category: category),
                .teacherStudentsList(selectedCategory: category, initialFilter: nil)
            ]

        case .sobre:
            return [
                .teacherDashboard(category: category),
                .teacherStudentsList(selectedCategory: category, initialFilter: nil),
                .sobre
            ]

        case .perfil:
            return [
                .teacherDashboard(category: category),
                .teacherStudentsList(selectedCategory: category, initialFilter: nil),
                .sobre,
                .perfil
            ]
        }
    }

    // ✅ agora recebe category para não hardcodear crossfit
    private func goTeacherHome(category: TreinoTipo) {
        path = teacherCanonicalStack(category: category, destination: .home)
    }

    // Navega para a lista de alunos do professor
    private func goTeacherAlunos(category: TreinoTipo) {
        path = teacherCanonicalStack(category: category, destination: .alunos)
    }

    // Navega para a tela Sobre do professor
    private func goTeacherSobre(category: TreinoTipo) {
        path = teacherCanonicalStack(category: category, destination: .sobre)
    }

    // Navega para o perfil do professor
    private func goTeacherPerfil(category: TreinoTipo) {
        path = teacherCanonicalStack(category: category, destination: .perfil)
    }
}

// Item individual do footer com ícone e título
private struct FooterItem: View {

    // Define o tipo de ícone usado no item
    enum Icon {
        case system(String)
        case custom(AnyView)
    }

    let icon: Icon
    let title: String
    let isSelected: Bool
    let width: CGFloat

    // Constrói o layout do item com ícone e texto
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

