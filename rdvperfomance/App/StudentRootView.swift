import SwiftUI

struct StudentRootView: View {
    @EnvironmentObject private var session: AppSession

    @State private var selectedSection: StudentMainSection = .agenda
    @State private var agendaPath: [AppRoute] = []
    @State private var recordsPath: [AppRoute] = []
    @State private var profilePath: [AppRoute] = []

    var body: some View {
        Group {
            switch selectedSection {
            case .agenda:
                NavigationStack(path: $agendaPath) {
                    StudentAgendaView(
                        path: $agendaPath,
                        studentId: session.uid ?? "",
                        studentName: session.userName ?? ""
                    )
                    .navigationDestination(for: AppRoute.self, destination: agendaDestination)
                }
            case .records:
                NavigationStack(path: $recordsPath) {
                    StudentPersonalRecordsView(path: $recordsPath, onBack: { select(.agenda) })
                        .navigationDestination(for: AppRoute.self, destination: recordsDestination)
                }
            case .profile:
                NavigationStack(path: $profilePath) {
                    ProfileView(path: $profilePath, onBack: { select(.agenda) })
                        .navigationDestination(for: AppRoute.self, destination: profileDestination)
                }
            }
        }
        .environment(\.selectStudentMainSection, select)
        .onChange(of: profilePath) { oldValue, newValue in
            #if DEBUG
            print("[NAV][ROOT] profilePath:", oldValue, "->", newValue)
            #endif
        }
    }

    private func select(_ section: StudentMainSection) {
        guard selectedSection != section else { return }

        switch section {
        case .agenda: agendaPath.removeAll()
        case .records: recordsPath.removeAll()
        case .profile: profilePath.removeAll()
        }

        selectedSection = section
    }

    @ViewBuilder
    private func agendaDestination(_ route: AppRoute) -> some View {
        switch route {
        case .studentWeekDetail(let studentId, let weekId, let weekTitle):
            StudentWeekDetailView(path: $agendaPath, studentId: studentId, weekId: weekId, weekTitle: weekTitle)
        case .studentDayDetail(let weekId, let day, let weekTitle):
            StudentDayDetailView(path: $agendaPath, weekId: weekId, day: day, weekTitle: weekTitle)
        case .studentMessages(let category):
            StudentMessagesView(path: $agendaPath, category: category)
        case .studentFeedbacks(let category):
            StudentFeedbacksView(path: $agendaPath, category: category)
        case .treinos(let tipo):
            TreinosView(path: $agendaPath, tipo: tipo)
        case .crossfitMenu:
            CrossfitMenuView(path: $agendaPath)
        case .sobre:
            AboutView(path: $agendaPath)
        case .arExercise(let weekId, let dayId):
            ARExerciseView(path: $agendaPath, weekId: weekId, dayId: dayId)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func recordsDestination(_ route: AppRoute) -> some View {
        switch route {
        case .studentPersonalRecordsBarbell:
            StudentBarbellPersonalRecordsView(path: $recordsPath)
        case .studentPersonalRecordsGymnastic:
            StudentGymnasticPersonalRecordsView(path: $recordsPath)
        case .studentPersonalRecordsEndurance:
            StudentEndurancePersonalRecordsView(path: $recordsPath)
        case .studentPersonalRecordsNotables:
            StudentNotablesPersonalRecordsView(path: $recordsPath)
        case .studentPersonalRecordsGirls:
            StudentGirlsPersonalRecordsView(path: $recordsPath)
        case .studentPersonalRecordsOpen:
            StudentOpenPersonalRecordsView(path: $recordsPath)
        case .studentPersonalRecordsHeroes:
            StudentHeroesPersonalRecordsView(path: $recordsPath)
        case .studentPersonalRecordsCampeonatos:
            StudentCampeonatosPersonalRecordsView(path: $recordsPath)
        case .studentPersonalRecordsCrossfitGames:
            StudentCrossfitGamesPersonalRecordsView(path: $recordsPath)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func profileDestination(_ route: AppRoute) -> some View {
        switch route {
        case .configuracoes:
            SettingsView(path: $profilePath)
        case .editarPerfil:
            EditProfileView(path: $profilePath)
        case .alterarSenha:
            ChangePasswordView(path: $profilePath)
        case .excluirConta:
            DeleteAccountView(path: $profilePath)
        case .sobre:
            AboutView(path: $profilePath)
        case .infoLegal(let kind):
            InfoLegalView(path: $profilePath, kind: kind)
        case .spriteDemo:
            SpriteDemoView(path: $profilePath)
        case .studentMessages(let category):
            StudentMessagesView(path: $profilePath, category: category)
        case .studentFeedbacks(let category):
            StudentFeedbacksView(path: $profilePath, category: category)
        default:
            EmptyView()
        }
    }
}
