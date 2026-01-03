import SwiftUI
import Combine

// MARK: - Aluno/Professor: Agenda (lista de semanas)
struct StudentAgendaView: View {

    @Binding var path: [AppRoute]
    let studentId: String
    let studentName: String

    @EnvironmentObject private var session: AppSession

    @AppStorage("ultimoTreinoSelecionado")
    private var ultimoTreinoSelecionado: String = TreinoTipo.crossfit.rawValue

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

    private var isTeacherViewing: Bool { session.userType == .TRAINER }

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

            if isTeacherViewing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { pop() } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                }
            }

            ToolbarItem(placement: .principal) {
                Text("Agenda")
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

        // ✅ Sempre que voltar para a Agenda, recarrega os metadados
        .onAppear {
            Task { await vm.loadWeeksAndMeta() }
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

            Text("Aluno: \(studentName)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.55))

            Text("Selecione uma semana para ver os dias.")
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

    private var weeksList: some View {
        VStack(spacing: 0) {
            ForEach(Array(vm.weeks.enumerated()), id: \.offset) { item in
                let idx = item.offset
                let week = item.element

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

                            Text(vm.subtitleForWeek(week))
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

            Button { Task { await vm.loadWeeksAndMeta() } } label: {
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

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

// MARK: - ViewModel
@MainActor
final class StudentAgendaViewModel: ObservableObject {

    @Published private(set) var weeks: [TrainingWeekFS] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // weekId -> "12/01/2026 a 14/01/2026"
    private var weekRangeText: [String: String] = [:]

    // weekId -> 35
    private var weekProgressPercent: [String: Int] = [:]

    private let studentId: String
    private let repository: FirestoreRepository

    init(studentId: String, repository: FirestoreRepository) {
        self.studentId = studentId
        self.repository = repository
    }

    func loadWeeksAndMeta() async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await repository.getWeeksForStudent(studentId: studentId)
            self.weeks = result

            await loadMetaForWeeks(result)

        } catch {
            self.errorMessage = (error as NSError).localizedDescription
        }

        isLoading = false
    }

    private func loadMetaForWeeks(_ weeks: [TrainingWeekFS]) async {

        // ✅ limpa cache antes de recarregar (garante atualização)
        weekRangeText.removeAll()
        weekProgressPercent.removeAll()

        await withTaskGroup(of: Void.self) { group in
            for week in weeks {
                guard let weekId = week.id, !weekId.isEmpty else { continue }

                group.addTask { [studentId] in
                    do {
                        let days = try await self.repository.getDaysForWeek(weekId: weekId)
                        if let range = StudentAgendaViewModel.computeRangeTextStatic(days: days) {
                            await MainActor.run { self.weekRangeText[weekId] = range }
                        }

                        let p = try await self.repository.getWeekProgress(weekId: weekId, studentId: studentId)
                        let percent = StudentAgendaViewModel.computePercentStatic(completed: p.completed, total: p.total)
                        await MainActor.run { self.weekProgressPercent[weekId] = percent }

                    } catch {
                        // fallback silencioso
                    }
                }
            }
        }

        // força refresh da lista
        objectWillChange.send()
    }

    func subtitleForWeek(_ week: TrainingWeekFS) -> String {
        guard let weekId = week.id else { return "Treinos da semana" }

        let range = weekRangeText[weekId] ?? "Treinos da semana"
        let percent = weekProgressPercent[weekId] ?? 0

        return "\(range) • \(percent)%"
    }

    // ✅ STATIC / NON-ACTOR helpers
    nonisolated static func computePercentStatic(completed: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        let v = (Double(completed) / Double(total)) * 100.0
        return Int(v.rounded())
    }

    nonisolated static func computeRangeTextStatic(days: [TrainingDayFS]) -> String? {
        let dates = days.compactMap { $0.date }
        guard let minDate = dates.min(), let maxDate = dates.max() else { return nil }

        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "dd/MM/yyyy"

        return "\(f.string(from: minDate)) a \(f.string(from: maxDate))"
    }
}

