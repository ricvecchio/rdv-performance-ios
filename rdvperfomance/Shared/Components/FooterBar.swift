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

        case .homeSobre(let isHomeSelected, _):
            HStack(spacing: 28) {
                Button { goHomeBasic() } label: {
                    FooterItem(icon: .system("house"), title: "Home", isSelected: isHomeSelected, width: Theme.Layout.footerItemWidthHomeSobre)
                }
                .buttonStyle(.plain)
            }

        case .homeSobrePerfil(let isHomeSelected, _, let isPerfilSelected):
            HStack(spacing: 26) {
                Button { goHomeBasic() } label: {
                    FooterItem(icon: .system("house"), title: "Home", isSelected: isHomeSelected, width: Theme.Layout.footerItemWidthHomeSobrePerfil)
                }
                .buttonStyle(.plain)

                Button { goPerfilBasic() } label: {
                    FooterItem(icon: .system("person"), title: "Perfil", isSelected: isPerfilSelected, width: Theme.Layout.footerItemWidthHomeSobrePerfil)
                }
                .buttonStyle(.plain)
            }

        case .treinos(let treinoTitle, let treinoIcon, let isHomeSelected, let isTreinoSelected, _):
            HStack(spacing: 28) {
                Button { goHomeBasic() } label: {
                    FooterItem(icon: .system("house"), title: "Home", isSelected: isHomeSelected, width: Theme.Layout.footerItemWidthTreinos)
                }
                .buttonStyle(.plain)

                FooterItem(icon: .custom(treinoIcon), title: treinoTitle, isSelected: isTreinoSelected, width: Theme.Layout.footerItemWidthTreinos)
            }

        case .treinosComPerfil(let treinoTitle, let treinoIcon, let isHomeSelected, let isTreinoSelected, _, let isPerfilSelected):
            HStack(spacing: 16) {
                Button { goHomeBasic() } label: {
                    FooterItem(icon: .system("house"), title: "Home", isSelected: isHomeSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)

                FooterItem(icon: .custom(treinoIcon), title: treinoTitle, isSelected: isTreinoSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)

                Button { goPerfilBasic() } label: {
                    FooterItem(icon: .system("person"), title: "Perfil", isSelected: isPerfilSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)
            }

        // ✅ ALUNO (3 ícones)
        case .agendaSobrePerfil(let isAgendaSelected, let isSobreSelected, let isPerfilSelected):
            HStack(spacing: 28) {
                Button { goAgenda() } label: {
                    FooterItem(icon: .system("calendar"), title: "Agenda", isSelected: isAgendaSelected, width: Theme.Layout.footerItemWidthHomeSobrePerfil)
                }
                .buttonStyle(.plain)

                Button { goPersonalRecords() } label: {
                    FooterItem(icon: .system("trophy.fill"), title: "Recordes", isSelected: isSobreSelected, width: Theme.Layout.footerItemWidthHomeSobrePerfil)
                }
                .buttonStyle(.plain)

                Button { goPerfilStudent() } label: {
                    FooterItem(icon: .system("person"), title: "Perfil", isSelected: isPerfilSelected, width: Theme.Layout.footerItemWidthHomeSobrePerfil)
                }
                .buttonStyle(.plain)
            }

        // ✅ ALUNO (4 ícones)
        case .agendaTreinosSobrePerfil(let isAgendaSelected, let isTreinosSelected, let isSobreSelected, let isPerfilSelected):
            HStack(spacing: 16) {
                Button { goAgenda() } label: {
                    FooterItem(icon: .system("calendar"), title: "Agenda", isSelected: isAgendaSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)

                Button { goTreinosAluno() } label: {
                    FooterItem(icon: .system("figure.strengthtraining.traditional"), title: "Treinos", isSelected: isTreinosSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)

                Button { goPersonalRecords() } label: {
                    FooterItem(icon: .system("trophy.fill"), title: "Recordes", isSelected: isSobreSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)

                Button { goPerfilStudent() } label: {
                    FooterItem(icon: .system("person"), title: "Perfil", isSelected: isPerfilSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)
            }

        // ✅ PROFESSOR (3 ícones) — espaçamento igual ao ALUNO
        case .teacherHomeAlunosSobrePerfil(let selectedCategory, let isHomeSelected, let isAlunosSelected, _, let isPerfilSelected):
            HStack(spacing: 28) {
                Button { goTeacherHome(category: selectedCategory) } label: {
                    FooterItem(icon: .system("house"), title: "Home", isSelected: isHomeSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)

                Button { goTeacherAlunos(category: selectedCategory) } label: {
                    FooterItem(icon: .system("person.3"), title: "Alunos", isSelected: isAlunosSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)

                Button { goTeacherPerfil(category: selectedCategory) } label: {
                    FooterItem(icon: .system("person"), title: "Perfil", isSelected: isPerfilSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)
            }

        // ✅ PROFESSOR (3 ícones) — espaçamento igual ao ALUNO
        case .teacherHomeAlunoSobrePerfil(let selectedCategory, let isHomeSelected, let isAlunoSelected, _, let isPerfilSelected):
            HStack(spacing: 28) {
                Button { goTeacherHome(category: selectedCategory) } label: {
                    FooterItem(icon: .system("house"), title: "Home", isSelected: isHomeSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)

                Button { goTeacherAlunos(category: selectedCategory) } label: {
                    FooterItem(icon: .system("person"), title: "Aluno", isSelected: isAlunoSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)

                Button { goTeacherPerfil(category: selectedCategory) } label: {
                    FooterItem(icon: .system("person.fill"), title: "Perfil", isSelected: isPerfilSelected, width: Theme.Layout.footerItemWidthTreinosComPerfil)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Métodos de navegação do rodapé
    //
    // REGRA: cada toque produz exatamente UMA mutação do path.
    // Rotas intermediárias artificiais foram removidas pois forçavam instanciação
    // desnecessária de Views e disparavam .task / .onAppear, criando condições de corrida
    // com o gesto de swipe-back e causando a necessidade de múltiplos toques.

    // MARK: Básico (Home, Sobre, Perfil sem contexto específico de aluno/professor)
    private func goHomeBasic() {
        guard !path.isEmpty else { return }
        path = []
    }

    private func goPerfilBasic() {
        let target: AppRoute = .perfil
        guard path.last != target else { return }
        path = [target]
    }

    // MARK: Aluno
    // A tela raiz do aluno é StudentAgendaView; path vazio = Agenda.
    private func goAgenda() {
        guard !path.isEmpty else { return }
        path = []
    }

    private func goTreinosAluno() {
        // Treinos do aluno também parte da agenda (root)
        guard !path.isEmpty else { return }
        path = []
    }

    private func goPersonalRecords() {
        let target: AppRoute = .studentPersonalRecords
        guard path.last != target else { return }
        path = [target]
    }

    private func goPerfilStudent() {
        let target: AppRoute = .perfil
        guard path.last != target else { return }
        path = [target]
    }

    // MARK: Professor
    // A tela raiz do professor é TeacherDashboardView; path vazio = Home.
    private func goTeacherHome(category: TreinoTipo) {
        guard !path.isEmpty else { return }
        path = []
    }

    private func goTeacherAlunos(category: TreinoTipo) {
        let target: AppRoute = .teacherStudentsList(selectedCategory: category, initialFilter: nil)
        guard path.last != target else { return }
        path = [target]
    }

    private func goTeacherSobre(category: TreinoTipo) {
        let target: AppRoute = .sobre
        guard path.last != target else { return }
        path = [target]
    }

    private func goTeacherPerfil(category: TreinoTipo) {
        let target: AppRoute = .perfil
        guard path.last != target else { return }
        path = [target]
    }
}

// Item individual do footer com ícone e título
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

