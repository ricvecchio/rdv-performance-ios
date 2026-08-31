import SwiftUI
import Foundation

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
    @Environment(\.selectStudentMainSection) private var selectStudentMainSection
    @Environment(\.selectTeacherMainSection) private var selectTeacherMainSection
    @State private var teacherStudentActivityCount = 0

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
        .task(id: session.uid ?? "") {
            await loadTeacherStudentActivityCount()
        }
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
                    teacherStudentsFooterItem(isSelected: isAlunosSelected)
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

    // MARK: - Seleção de seção principal

    private func goHomeBasic() {
        if session.isTrainer {
            selectTeacherMainSection(.home)
        } else {
            selectStudentMainSection(.agenda)
        }
    }

    private func goPerfilBasic() {
        if session.isTrainer {
            selectTeacherMainSection(.profile)
        } else {
            selectStudentMainSection(.profile)
        }
    }

    private func goAgenda() {
        selectStudentMainSection(.agenda)
    }

    private func goTreinosAluno() {
        selectStudentMainSection(.agenda)
    }

    private func goPersonalRecords() {
        selectStudentMainSection(.records)
    }

    private func goPerfilStudent() {
        selectStudentMainSection(.profile)
    }

    private func goTeacherHome(category: TreinoTipo) {
        selectTeacherMainSection(.home)
    }

    private func goTeacherAlunos(category: TreinoTipo) {
        selectTeacherMainSection(.students)
    }

    private func goTeacherPerfil(category: TreinoTipo) {
        selectTeacherMainSection(.profile)
    }

    private func teacherStudentsFooterItem(isSelected: Bool) -> some View {
        ZStack(alignment: .topTrailing) {
            FooterItem(
                icon: .system("person.3"),
                title: "Alunos",
                isSelected: isSelected,
                width: Theme.Layout.footerItemWidthTreinosComPerfil
            )

            if teacherStudentActivityCount > 0 && !isSelected {
                Text("\(teacherStudentActivityCount)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.red))
                    .offset(x: 7, y: -6)
            }
        }
    }

    private func loadTeacherStudentActivityCount() async {
        guard session.isTrainer, let teacherId = session.uid, !teacherId.isEmpty else {
            teacherStudentActivityCount = 0
            return
        }

        let key = "teacherStudentActivitiesLastSeen.\(teacherId)"
        let lastSeen = UserDefaults.standard.object(forKey: key) as? Date

        do {
            async let invites = FirestoreRepository.shared.getInvitesSentByTeacher(
                teacherId: teacherId,
                status: nil,
                limit: 200
            )
            async let requests = FirestoreRepository.shared.getPendingLinkRequestsForTeacher(teacherId: teacherId)
            let (sentInvites, pendingRequests) = try await (invites, requests)

            let newRequests = pendingRequests.filter {
                guard let lastSeen else { return true }
                return ($0.createdAt?.dateValue() ?? .distantPast) > lastSeen
            }.count
            let updatedInvites: Int
            if let lastSeen {
                updatedInvites = sentInvites.filter {
                    let status = $0.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    return (status == "accepted" || status == "declined")
                        && ($0.updatedAt?.dateValue() ?? .distantPast) > lastSeen
                }.count
            } else {
                updatedInvites = 0
            }

            teacherStudentActivityCount = newRequests + updatedInvites
        } catch {
            teacherStudentActivityCount = 0
        }
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
