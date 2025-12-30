import SwiftUI
import Combine

struct StudentAgendaView: View {

    @Binding var path: [AppRoute]
    let studentId: String
    let studentName: String

    @StateObject private var vm: StudentAgendaViewModel
    private let contentMaxWidth: CGFloat = 380

    init(
        path: Binding<[AppRoute]>,
        studentId: String,
        studentName: String,
        repository: FirestoreRepository = .shared
    ) {
        self._path = path
        self.studentId = studentId
        self.studentName = studentName
        _vm = StateObject(wrappedValue: StudentAgendaViewModel(studentId: studentId, repository: repository))
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

                FooterBar(
                    path: $path,
                    kind: .agendaSobrePerfil(
                        isAgendaSelected: true,
                        isSobreSelected: false,
                        isPerfilSelected: false
                    )
                )
                .frame(height: Theme.Layout.footerHeight)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                MiniProfileHeader(imageName: "rdv_eu", size: 38)
                    .background(Color.clear)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await vm.loadWeeks() }
    }

    // MARK: - Header (apenas cores no padrão do app)
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Agenda")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)

            Text("Aluno: \(studentName)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.55))

            Text("Selecione uma semana para ver os dias.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Card padrão (igual Settings/Profile)
    private var contentCard: some View {
        VStack(spacing: 0) {
            if vm.isLoading {
                loadingView
            } else if let errorMessage = vm.errorMessage {
                errorView(message: errorMessage)
            } else if vm.weeks.isEmpty {
                emptyView
            } else {
                weeksList
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    // MARK: - Lista no estilo “cardRow” (sem mini-cards)
    private var weeksList: some View {
        VStack(spacing: 0) {
            ForEach(Array(vm.weeks.enumerated()), id: \.offset) { idx, week in

                Button {
                    guard let weekId = week.id, !weekId.isEmpty else {
                        vm.errorMessage = "Não foi possível abrir a semana: weekId está vazio."
                        return
                    }

                    path.append(.studentWeekDetail(
                        studentId: studentId,
                        weekId: weekId,
                        weekTitle: week.weekTitle
                    ))
                } label: {
                    HStack(spacing: 14) {

                        Image(systemName: "calendar")
                            .font(.system(size: 18))
                            .foregroundColor(.green.opacity(0.85))
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(week.weekTitle)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.92))

                            Text(week.subtitleText)
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

                if idx < vm.weeks.count - 1 {
                    innerDivider(leading: 54)
                }
            }
        }
    }

    // MARK: - Estados (cores no padrão)
    private var loadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("Carregando semanas...")
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

            Button {
                Task { await vm.loadWeeks() }
            } label: {
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
            Text("Nenhuma semana cadastrada")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text("O professor ainda não publicou treinos para este aluno.")
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
}

@MainActor
final class StudentAgendaViewModel: ObservableObject {

    @Published private(set) var weeks: [TrainingWeekFS] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let studentId: String
    private let repository: FirestoreRepository

    init(studentId: String, repository: FirestoreRepository) {
        self.studentId = studentId
        self.repository = repository
    }

    func loadWeeks() async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await repository.getWeeksForStudent(studentId: studentId)
            self.weeks = result
        } catch {
            self.errorMessage = (error as NSError).localizedDescription
        }

        isLoading = false
    }
}

private extension TrainingWeekFS {
    var subtitleText: String { "Treinos da semana" }
}

