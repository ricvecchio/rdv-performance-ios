import SwiftUI

/// Raiz de navegação do ALUNO.
///
/// Esta view é o coração da correção arquitetural: ela é a ÚNICA dona da
/// "seção principal" selecionada (Treinos / Recordes / Perfil) e de TRÊS
/// pilhas de navegação hierárquica totalmente independentes — uma por seção.
///
/// Por quê:
/// Antes desta refatoração, o Footer do aluno mutava o MESMO `path` usado
/// pelo `NavigationStack` global (`path = []`, `path = [.studentPersonalRecords]`,
/// `path = [.perfil]`). Ou seja, trocar de aba no rodapé era tratado como
/// push/pop de navegação hierárquica. Isso criava condições de corrida reais
/// entre: (1) o toque no rodapé mutando `path`, (2) uma transição de
/// push/pop do UIKit ainda em andamento, e (3) o gesto de swipe-back
/// (`interactivePopGestureRecognizer`) competindo pelo mesmo estado. O
/// resultado observável era exatamente o reportado: troca de aba atrasada,
/// necessidade de tocar duas vezes, e o botão `<` de Recordes não fazendo
/// nada (porque `path.removeLast()` era um no-op quando `path` já estava
/// vazio — Recordes SEMPRE chegava com `path = [.studentPersonalRecords]`,
/// ou seja, `path.count == 1`; ao dar pop, o "topo" virava a raiz do
/// NavigationStack, mas nada de fato pedia para trocar para Treinos).
///
/// Como ficou:
/// - `selectedSection` é só um enum (`StudentMainSection`), trocado por uma
///   simples atribuição de estado — nunca um push/pop.
/// - `workoutsPath` / `recordsPath` / `profilePath` são 3 arrays de `AppRoute`
///   independentes, cada um dono de um `NavigationStack` próprio. Cada um
///   representa SOMENTE os filhos hierárquicos daquela seção (ex.:
///   `recordsPath = [.studentPersonalRecordsBarbell]`, nunca
///   `[.studentPersonalRecords, .studentPersonalRecordsBarbell]` — a própria
///   seção nunca aparece dentro do seu próprio path).
/// - Somente a seção selecionada é montada. Assim, a largura intrínseca de
///   uma aba inativa não pode alterar o viewport da tela visível.
/// - O botão `<` da raiz de Recordes e da raiz de Perfil deixou de ser um
///   pop (que já não fazia sentido, pois essas telas são a RAIZ da sua
///   própria pilha) e passou a significar exatamente o que o produto exige:
///   "voltar para Treinos" == `selectedSection = .agenda`.
struct StudentRootView: View {

    @EnvironmentObject private var session: AppSession

    let studentId: String
    let studentName: String

    @State private var selectedSection: StudentMainSection = .home

    @State private var homePath: [AppRoute] = []
    @State private var workoutsPath: [AppRoute] = []
    @State private var recordsPath: [AppRoute] = []
    @State private var profilePath: [AppRoute] = []
    @State private var workoutsInitialWeekId: String?
    @State private var workoutsInitialDayId: String?

    var body: some View {
        selectedTab
            .environment(\.selectStudentMainSection, selectSection)
    }

    @ViewBuilder
    private var selectedTab: some View {
        switch selectedSection {
        case .home:
            homeTab
        case .agenda:
            workoutsTab
        case .records:
            recordsTab
        case .profile:
            profileTab
        }
    }

    // MARK: - Seleção de seção (chamada pelo FooterBar de qualquer tela do aluno)

    /// Troca a seção principal. Se a seção de destino já estiver selecionada
    /// E já estiver na sua raiz, não faz nada (idempotente). Caso contrário,
    /// a pilha local da seção de destino é resetada para a raiz — conforme
    /// decisão de produto: "ao selecionar um ícone do rodapé, abrir a raiz
    /// daquela seção" (não é necessário preservar profundidade entre trocas
    /// de aba).
    private func selectSection(_ target: StudentMainSection) {
        let alreadyAtRoot: Bool
        switch target {
        case .home: alreadyAtRoot = homePath.isEmpty
        case .agenda: alreadyAtRoot = workoutsPath.isEmpty
        case .records: alreadyAtRoot = recordsPath.isEmpty
        case .profile: alreadyAtRoot = profilePath.isEmpty
        }

        if selectedSection == target && alreadyAtRoot { return }

        switch target {
        case .home: homePath = []
        case .agenda: workoutsPath = []
        case .records: recordsPath = []
        case .profile: profilePath = []
        }

        selectedSection = target
    }

    private func openWorkouts(weekId: String, dayId: String) {
        workoutsPath = []
        workoutsInitialWeekId = weekId
        workoutsInitialDayId = dayId
        selectedSection = .agenda
    }

    // MARK: - Treinos

    private var homeTab: some View {
        NavigationStack(path: $homePath) {
            StudentDashboardView(
                path: $homePath,
                studentId: studentId,
                onSelectSection: selectSection,
                onSelectWorkout: openWorkouts
            )
            .navigationDestination(for: AppRoute.self) { route in
                workoutsDestination(for: route, path: $homePath)
            }
        }
    }

    private var workoutsTab: some View {
        NavigationStack(path: $workoutsPath) {
            StudentWorkoutsView(
                path: $workoutsPath,
                studentId: studentId,
                studentName: studentName,
                initialExpandedWeekId: workoutsInitialWeekId,
                initialExpandedDayId: workoutsInitialDayId,
                onInitialExpansionHandled: {
                    workoutsInitialWeekId = nil
                    workoutsInitialDayId = nil
                },
                onSelectSection: selectSection
            )
            .navigationDestination(for: AppRoute.self) { route in
                workoutsDestination(for: route, path: $workoutsPath)
            }
        }
    }

    @ViewBuilder
    private func workoutsDestination(for route: AppRoute, path: Binding<[AppRoute]>) -> some View {
        switch route {

        case .studentWeekDetail(let studentId, let weekId, let weekTitle, let selectedDayId):
            StudentWeekDetailView(
                path: path,
                studentId: studentId,
                weekId: weekId,
                weekTitle: weekTitle,
                initialExpandedDayId: selectedDayId,
                onSelectSection: selectSection
            )

        case .studentDayDetail(let weekId, let day, let weekTitle):
            StudentDayDetailView(
                path: path,
                weekId: weekId,
                day: day,
                weekTitle: weekTitle,
                onSelectSection: selectSection
            )

        case .arExercise(let weekId, let dayId):
            ARExerciseView(path: path, weekId: weekId, dayId: dayId)

        default:
            EmptyView()
        }
    }

    // MARK: - Recordes

    private var recordsTab: some View {
        NavigationStack(path: $recordsPath) {
            StudentPersonalRecordsView(
                path: $recordsPath,
                onBack: { selectSection(.agenda) },
                onSelectSection: selectSection
            )
            .navigationDestination(for: AppRoute.self) { route in
                recordsDestination(for: route)
            }
        }
    }

    @ViewBuilder
    private func recordsDestination(for route: AppRoute) -> some View {
        switch route {

        case .studentPersonalRecordsBarbell:
            StudentBarbellPersonalRecordsView(path: $recordsPath, onSelectSection: selectSection)

        case .studentPersonalRecordsGymnastic:
            StudentGymnasticPersonalRecordsView(path: $recordsPath, onSelectSection: selectSection)

        case .studentPersonalRecordsEndurance:
            StudentEndurancePersonalRecordsView(path: $recordsPath, onSelectSection: selectSection)

        case .studentPersonalRecordsNotables:
            StudentNotablesPersonalRecordsView(path: $recordsPath, onSelectSection: selectSection)

        case .studentPersonalRecordsGirls:
            StudentGirlsPersonalRecordsView(path: $recordsPath, onSelectSection: selectSection)

        case .studentPersonalRecordsOpen:
            StudentOpenPersonalRecordsView(path: $recordsPath, onSelectSection: selectSection)

        case .studentPersonalRecordsHeroes:
            StudentHeroesPersonalRecordsView(path: $recordsPath, onSelectSection: selectSection)

        case .studentPersonalRecordsCampeonatos:
            StudentCampeonatosPersonalRecordsView(path: $recordsPath, onSelectSection: selectSection)

        case .studentPersonalRecordsCrossfitGames:
            StudentCrossfitGamesPersonalRecordsView(path: $recordsPath, onSelectSection: selectSection)

        default:
            EmptyView()
        }
    }

    // MARK: - Perfil

    private var profileTab: some View {
        NavigationStack(path: $profilePath) {
            ProfileView(
                path: $profilePath,
                onBack: { selectSection(.agenda) }
            )
            .navigationDestination(for: AppRoute.self) { route in
                profileDestination(for: route)
            }
        }
    }

    @ViewBuilder
    private func profileDestination(for route: AppRoute) -> some View {
        switch route {

        case .configuracoes:
            SettingsView(path: $profilePath)

        case .editarPerfil:
            EditProfileView(path: $profilePath)

        case .alterarSenha:
            ChangePasswordView(path: $profilePath)

        case .excluirConta:
            DeleteAccountView(path: $profilePath)

        case .infoLegal(let kind):
            InfoLegalView(path: $profilePath, kind: kind, onSelectSection: selectSection)

        case .sobre:
            AboutView(path: $profilePath, onSelectSection: selectSection)

        case .spriteDemo:
            SpriteDemoView(path: $profilePath, onSelectSection: selectSection)

        case .studentMessages(let category):
            StudentMessagesView(path: $profilePath, category: category, onSelectSection: selectSection)

        case .studentFeedbacks(let category):
            StudentFeedbacksView(path: $profilePath, category: category, onSelectSection: selectSection)

        case .studentTeachers(let studentEmail):
            StudentTeachersView(
                path: $profilePath,
                studentEmail: studentEmail,
                onSelectSection: selectSection
            )

        default:
            EmptyView()
        }
    }
}
