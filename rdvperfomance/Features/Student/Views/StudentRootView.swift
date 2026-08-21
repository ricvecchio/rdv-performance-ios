import SwiftUI

/// Raiz de navegação do ALUNO.
///
/// Esta view é o coração da correção arquitetural: ela é a ÚNICA dona da
/// "seção principal" selecionada (Agenda / Recordes / Perfil) e de TRÊS
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
/// NavigationStack, mas nada de fato pedia para trocar para a Agenda).
///
/// Como ficou:
/// - `selectedSection` é só um enum (`StudentMainSection`), trocado por uma
///   simples atribuição de estado — nunca um push/pop.
/// - `agendaPath` / `recordsPath` / `profilePath` são 3 arrays de `AppRoute`
///   independentes, cada um dono de um `NavigationStack` próprio. Cada um
///   representa SOMENTE os filhos hierárquicos daquela seção (ex.:
///   `recordsPath = [.studentPersonalRecordsBarbell]`, nunca
///   `[.studentPersonalRecords, .studentPersonalRecordsBarbell]` — a própria
///   seção nunca aparece dentro do seu próprio path).
/// - As 3 seções ficam sempre montadas (via `TabView(selection:)` com a tab
///   bar nativa oculta), preservando os `@StateObject` (ex.:
///   `StudentAgendaViewModel`) entre trocas de aba — nada é destruído e
///   recriado só porque o usuário tocou no rodapé.
/// - O botão `<` da raiz de Recordes e da raiz de Perfil deixou de ser um
///   pop (que já não fazia sentido, pois essas telas são a RAIZ da sua
///   própria pilha) e passou a significar exatamente o que o produto exige:
///   "voltar para a Agenda" == `selectedSection = .agenda`.
struct StudentRootView: View {

    @EnvironmentObject private var session: AppSession

    let studentId: String
    let studentName: String

    @State private var selectedSection: StudentMainSection = .agenda

    @State private var agendaPath: [AppRoute] = []
    @State private var recordsPath: [AppRoute] = []
    @State private var profilePath: [AppRoute] = []

    // Um instalador de gesto de swipe-back por pilha: cada NavigationStack é
    // independente e precisa da sua própria instância (ver NavigationPopGestureFixer.swift).
    @State private var agendaGestureInstaller = NavigationPopGestureInstaller()
    @State private var recordsGestureInstaller = NavigationPopGestureInstaller()
    @State private var profileGestureInstaller = NavigationPopGestureInstaller()

    var body: some View {
        TabView(selection: $selectedSection) {

            agendaTab
                .tag(StudentMainSection.agenda)

            recordsTab
                .tag(StudentMainSection.records)

            profileTab
                .tag(StudentMainSection.profile)
        }
        // Mantém o design atual: a tab bar nativa do iOS nunca aparece, apenas
        // o FooterBar customizado renderizado por cada tela (inalterado
        // visualmente). O TabView aqui é usado só como mecanismo de
        // preservação de estado entre seções — não como UI.
        .toolbar(.hidden, for: .tabBar)
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
        case .agenda: alreadyAtRoot = agendaPath.isEmpty
        case .records: alreadyAtRoot = recordsPath.isEmpty
        case .profile: alreadyAtRoot = profilePath.isEmpty
        }

        if selectedSection == target && alreadyAtRoot { return }

        switch target {
        case .agenda: agendaPath = []
        case .records: recordsPath = []
        case .profile: profilePath = []
        }

        selectedSection = target
    }

    // MARK: - Agenda

    private var agendaTab: some View {
        NavigationStack(path: $agendaPath) {
            StudentAgendaView(
                path: $agendaPath,
                studentId: studentId,
                studentName: studentName,
                onSelectSection: selectSection
            )
            .background(
                NavigationPopGestureFixer(
                    installer: agendaGestureInstaller,
                    stackDepth: agendaPath.count
                )
            )
            .navigationDestination(for: AppRoute.self) { route in
                agendaDestination(for: route)
            }
        }
    }

    @ViewBuilder
    private func agendaDestination(for route: AppRoute) -> some View {
        switch route {

        case .studentWeekDetail(let studentId, let weekId, let weekTitle):
            StudentWeekDetailView(
                path: $agendaPath,
                studentId: studentId,
                weekId: weekId,
                weekTitle: weekTitle,
                onSelectSection: selectSection
            )

        case .studentDayDetail(let weekId, let day, let weekTitle):
            StudentDayDetailView(
                path: $agendaPath,
                weekId: weekId,
                day: day,
                weekTitle: weekTitle,
                onSelectSection: selectSection
            )

        case .arExercise(let weekId, let dayId):
            ARExerciseView(path: $agendaPath, weekId: weekId, dayId: dayId)

        default:
            EmptyView()
        }
    }

    // MARK: - Recordes

    private var recordsTab: some View {
        NavigationStack(path: $recordsPath) {
            StudentPersonalRecordsView(
                path: $recordsPath,
                onSelectSection: selectSection
            )
            .background(
                NavigationPopGestureFixer(
                    installer: recordsGestureInstaller,
                    stackDepth: recordsPath.count
                )
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
                onSelectSection: selectSection
            )
            .background(
                NavigationPopGestureFixer(
                    installer: profileGestureInstaller,
                    stackDepth: profilePath.count
                )
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
            SettingsView(path: $profilePath, onSelectSection: selectSection)

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

        default:
            EmptyView()
        }
    }
}
