import SwiftUI
import Combine

struct StudentWeekDetailView: View {

    @Binding var path: [AppRoute]

    let studentId: String
    let weekId: String
    let weekTitle: String

    @EnvironmentObject private var session: AppSession

    @AppStorage("ultimoTreinoSelecionado")
    private var ultimoTreinoSelecionado: String = TreinoTipo.crossfit.rawValue

    @StateObject private var vm: StudentWeekDetailViewModel
    private let contentMaxWidth: CGFloat = 380

    init(
        path: Binding<[AppRoute]>,
        studentId: String,
        weekId: String,
        weekTitle: String,
        repository: FirestoreRepository = .shared
    ) {
        self._path = path
        self.studentId = studentId
        self.weekId = weekId
        self.weekTitle = weekTitle
        _vm = StateObject(wrappedValue: StudentWeekDetailViewModel(weekId: weekId, repository: repository))
    }

    private var isTeacherViewing: Bool {
        session.userType == .TRAINER
    }

    private var teacherSelectedCategory: TreinoTipo {
        TreinoTipo(rawValue: ultimoTreinoSelecionado) ?? .crossfit
    }

    var body: some View {
        ZStack {

            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        header
                        contentCard
                    }
                    .frame(maxWidth: contentMaxWidth)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                    .frame(maxWidth: .infinity)
                }

                footer
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {

            // ✅ Agora sempre tem voltar
            ToolbarItem(placement: .navigationBarLeading) {
                Button { pop() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("Semana")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                MiniProfileHeader(imageName: "rdv_eu", size: 38)
                    .background(Color.clear)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            if vm.days.isEmpty && !vm.isLoading {
                await vm.loadDays()
            }
        }
    }

    private var footer: some View {
        Group {
            if isTeacherViewing {
                FooterBar(
                    path: $path,
                    kind: .teacherHomeAlunosSobrePerfil(
                        selectedCategory: teacherSelectedCategory,
                        isHomeSelected: false,
                        isAlunosSelected: true,
                        isSobreSelected: false,
                        isPerfilSelected: false
                    )
                )
            } else {
                FooterBar(
                    path: $path,
                    kind: .agendaSobrePerfil(
                        isAgendaSelected: true,
                        isSobreSelected: false,
                        isPerfilSelected: false
                    )
                )
            }
        }
        .frame(height: Theme.Layout.footerHeight)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.footerBackground)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {

            Text(weekTitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text("Dias de treino")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var contentCard: some View {
        VStack(spacing: 0) {
            if vm.isLoading {
                loadingView
            } else if let errorMessage = vm.errorMessage {
                errorView(message: errorMessage)
            } else if vm.days.isEmpty {
                emptyView
            } else {
                daysList
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private var daysList: some View {
        VStack(spacing: 0) {
            ForEach(Array(vm.days.enumerated()), id: \.offset) { idx, day in
                Button {
                    path.append(.studentDayDetail(day: day, weekTitle: weekTitle))
                } label: {
                    HStack(spacing: 14) {

                        Image(systemName: "flame.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green.opacity(0.85))
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(day.title)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.92))

                            Text(day.subtitleText)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.35))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if idx < vm.days.count - 1 {
                    innerDivider(leading: 54)
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("Carregando dias...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 10) {
            Text("Ops! Não foi possível carregar.")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)

            Button { Task { await vm.loadDays() } } label: {
                Text("Tentar novamente")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.green.opacity(0.16)))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 10)
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Text("Nenhum dia cadastrado")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text("O professor ainda não adicionou dias para esta semana.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 10)
    }

    private func innerDivider(leading: CGFloat) -> some View {
        Divider()
            .background(Theme.Colors.divider)
            .padding(.leading, leading)
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

@MainActor
final class StudentWeekDetailViewModel: ObservableObject {

    @Published private(set) var days: [TrainingDayFS] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let weekId: String
    private let repository: FirestoreRepository

    init(weekId: String, repository: FirestoreRepository) {
        self.weekId = weekId
        self.repository = repository
    }

    func loadDays() async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await repository.getDaysForWeek(weekId: weekId)
            self.days = result
        } catch {
            self.errorMessage = (error as NSError).localizedDescription
        }

        isLoading = false
    }
}

