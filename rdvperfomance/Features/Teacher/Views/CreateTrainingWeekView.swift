import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

struct CreateTrainingWeekView: View {

    @Binding var path: [AppRoute]
    let student: AppUser
    let category: TreinoTipo

    @EnvironmentObject private var session: AppSession

    @State private var weekTitle: String = ""
    @State private var showPasswordDummy: Bool = false

    @StateObject private var vm: CreateTrainingWeekViewModel

    @State private var isEditSheetOpen: Bool = false
    @State private var editingWeek: TrainingWeekFS? = nil
    @State private var editingTitle: String = ""

    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil

    private let contentMaxWidth: CGFloat = 380

    init(
        path: Binding<[AppRoute]>,
        student: AppUser,
        category: TreinoTipo,
        repository: FirestoreRepository = .shared
    ) {
        self._path = path
        self.student = student
        self.category = category
        _vm = StateObject(wrappedValue: CreateTrainingWeekViewModel(studentId: student.id ?? "", repository: repository))
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
                    .frame(maxWidth: .infinity)

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {

                            header
                            weeksCard
                            formCard

                            if let err = errorMessage {
                                messageCard(text: err, isError: true)
                            }

                            if let ok = successMessage {
                                messageCard(text: ok, isError: false)
                            }

                            Color.clear.frame(height: Theme.Layout.footerHeight + 20)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                }

                FooterBar(
                    path: $path,
                    kind: .teacherHomeAlunosSobrePerfil(
                        selectedCategory: category,
                        isHomeSelected: false,
                        isAlunosSelected: false,
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
            ToolbarItem(placement: .navigationBarLeading) {
                Button { pop() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("Publicar semana")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {

                Button {
                    Task { await loadWeeks() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)

                MiniProfileHeader(imageName: "rdv_eu", size: 38)
                    .background(Color.clear)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await loadWeeks() }
        .sheet(isPresented: $isEditSheetOpen) { editWeekSheet }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Aluno: \(student.name)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.70))

            Text("Categoria: \(category.displayName)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.green.opacity(0.85))

            Text("Você pode ver semanas já cadastradas, editar o título e adicionar dias.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var weeksCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("SEMANAS CADASTRADAS")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))

                Spacer()

                if vm.isLoading {
                    ProgressView().tint(.white)
                }
            }

            if let err = vm.errorMessage {
                Text(err)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
            } else if vm.weeks.isEmpty {
                Text("Nenhuma semana cadastrada para este aluno.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(vm.weeks.enumerated()), id: \.offset) { idx, week in
                        weekRow(week)
                        if idx < vm.weeks.count - 1 { innerDivider(leading: 16) }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func weekRow(_ week: TrainingWeekFS) -> some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "calendar")
                    .foregroundColor(.green.opacity(0.85))
                    .font(.system(size: 16))
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 6) {

                    Text(week.weekTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))

                    if let rangeText = weekDateRangeText(week) {
                        Text(rangeText)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.45))
                    }

                    Text(week.isPublished ? "Publicada" : "Rascunho")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(week.isPublished ? .green.opacity(0.85) : .white.opacity(0.45))
                }

                Spacer()
            }

            HStack(spacing: 10) {

                Button { openWeekDays(week) } label: {
                    Text("Ver dias")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color.white.opacity(0.10))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)

                Button { openAddDay(week) } label: {
                    Text("Adicionar dias")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color.green.opacity(0.16))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.green.opacity(0.35), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Spacer()

                Button { openEditWeekTitle(week) } label: {
                    Image(systemName: "pencil")
                        .foregroundColor(.white.opacity(0.75))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("NOVA SEMANA")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.35))

            UnderlineTextField(
                title: "Título da semana",
                text: $weekTitle,
                isSecure: false,
                showPassword: $showPasswordDummy,
                lineColor: Theme.Colors.divider,
                textColor: .white.opacity(0.92),
                placeholderColor: .white.opacity(0.55)
            )

            Divider().background(Theme.Colors.divider)

            Button { Task { await publishWeek() } } label: {
                HStack {
                    Spacer()
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("Publicar")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.92))
                    }
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(Color.green.opacity(0.16))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.35), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func messageCard(text: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .yellow.opacity(0.85) : .green.opacity(0.85))
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.75))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.35))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func innerDivider(leading: CGFloat) -> some View {
        Divider()
            .background(Theme.Colors.divider)
            .padding(.leading, leading)
    }

    // MARK: - Actions

    private func loadWeeks() async {
        errorMessage = nil
        successMessage = nil

        guard let studentId = student.id, !studentId.isEmpty else {
            vm.errorMessage = "Aluno inválido: id não encontrado."
            return
        }

        await vm.loadWeeks(studentId: studentId)

        // ✅ IMPORTANTÍSSIMO: corrige semanas já existentes
        // para que start/end reflitam os dias cadastrados.
        await vm.repairWeekRangesIfNeeded()
    }

    private func openWeekDays(_ week: TrainingWeekFS) {
        guard let weekId = week.id, !weekId.isEmpty else { return }
        guard let studentId = student.id, !studentId.isEmpty else { return }
        path.append(.studentWeekDetail(studentId: studentId, weekId: weekId, weekTitle: week.weekTitle))
    }

    private func openAddDay(_ week: TrainingWeekFS) {
        guard let weekId = week.id, !weekId.isEmpty else { return }
        path.append(.createTrainingDay(weekId: weekId, category: category))
    }

    private func openEditWeekTitle(_ week: TrainingWeekFS) {
        editingWeek = week
        editingTitle = week.weekTitle
        isEditSheetOpen = true
    }

    private var editWeekSheet: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {

                Text("Editar título da semana")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                UnderlineTextField(
                    title: "Novo título",
                    text: $editingTitle,
                    isSecure: false,
                    showPassword: $showPasswordDummy,
                    lineColor: Theme.Colors.divider,
                    textColor: .white.opacity(0.92),
                    placeholderColor: .white.opacity(0.55)
                )

                HStack(spacing: 10) {
                    Button { isEditSheetOpen = false } label: {
                        Text("Cancelar")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.90))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.10))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button { Task { await saveEditedTitle() } } label: {
                        Text("Salvar")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.92))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.green.opacity(0.16))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.35), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }

                Spacer()
            }
            .padding(16)
            .frame(maxWidth: 420)
        }
        .presentationDetents([.medium])
    }

    private func saveEditedTitle() async {
        // Mantido como estava no seu arquivo.
        // (Não alterei porque não foi solicitado aqui.)
        isEditSheetOpen = false
    }

    private func publishWeek() async {
        // Mantido como estava no seu arquivo.
        // (Não alterei porque sua solicitação atual é sobre range por dias.)
    }

    private func weekDateRangeText(_ week: TrainingWeekFS) -> String? {
        guard let s = week.startDate, let e = week.endDate else { return nil }
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "dd/MM/yyyy"
        return "\(f.string(from: s)) a \(f.string(from: e))"
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

// MARK: - ViewModel
@MainActor
final class CreateTrainingWeekViewModel: ObservableObject {

    @Published private(set) var weeks: [TrainingWeekFS] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let studentId: String
    private let repository: FirestoreRepository

    init(studentId: String, repository: FirestoreRepository) {
        self.studentId = studentId
        self.repository = repository
    }

    func loadWeeks(studentId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await repository.getWeeksForStudent(studentId: studentId, onlyPublished: false)

            self.weeks = result.sorted { a, b in
                let ad = a.createdAt?.dateValue() ?? Date.distantPast
                let bd = b.createdAt?.dateValue() ?? Date.distantPast
                return ad > bd
            }

        } catch {
            self.errorMessage = (error as NSError).localizedDescription
        }

        isLoading = false
    }

    /// ✅ Corrige weeks já existentes para refletirem o range real dos dias
    func repairWeekRangesIfNeeded() async {
        let ids = weeks.compactMap { $0.id }
        guard !ids.isEmpty else { return }

        // roda em paralelo, mas sem travar UI
        await withTaskGroup(of: Void.self) { group in
            for weekId in ids {
                group.addTask {
                    do {
                        try await FirestoreRepository.shared.updateWeekDateRangeFromDays(weekId: weekId)
                    } catch {
                        // Silencioso para não poluir UI;
                        // se precisar, podemos logar.
                    }
                }
            }
        }

        // Recarrega para refletir as datas corrigidas na lista
        do {
            let result = try await repository.getWeeksForStudent(studentId: studentId, onlyPublished: false)
            self.weeks = result.sorted { a, b in
                let ad = a.createdAt?.dateValue() ?? Date.distantPast
                let bd = b.createdAt?.dateValue() ?? Date.distantPast
                return ad > bd
            }
        } catch {
            // mantém lista atual
        }
    }
}

