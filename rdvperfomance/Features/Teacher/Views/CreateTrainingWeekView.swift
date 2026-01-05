// CreateTrainingWeekView.swift — Tela para publicar e gerenciar semanas de treino de um aluno
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

struct CreateTrainingWeekView: View {

    // Bindings, parâmetros e ViewModel
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

    // Estado para exclusão de semana
    @State private var weekPendingDelete: TrainingWeekFS? = nil
    @State private var showDeleteWeekConfirm: Bool = false
    @State private var isDeletingWeek: Bool = false

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

    // Corpo principal com header, lista de semanas e formulário de nova semana
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

                // Avatar do cabeçalho (foto real do usuário)
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await loadWeeks() }
        .sheet(isPresented: $isEditSheetOpen) { editWeekSheet }
        .alert("Excluir semana?", isPresented: $showDeleteWeekConfirm) {
            Button("Cancelar", role: .cancel) {
                weekPendingDelete = nil
            }
            Button("Excluir", role: .destructive) {
                Task { await confirmDeleteWeek() }
            }
        } message: {
            Text(deleteWeekMessageText())
        }
    }

    // Header com contexto do aluno e categoria
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

    // Card que exibe semanas existentes
    private var weeksCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("SEMANAS CADASTRADAS")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))

                Spacer()

                if vm.isLoading || isDeletingWeek {
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

    // Linha de cada semana com ações
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

                // Menu de ações por semana
                Menu {
                    Button {
                        openEditWeekTitle(week)
                    } label: {
                        Label("Editar título", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        weekPendingDelete = week
                        showDeleteWeekConfirm = true
                    } label: {
                        Label("Excluir semana", systemImage: "trash")
                    }

                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white.opacity(0.65))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .disabled(isDeletingWeek || vm.isLoading)
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
            .disabled(isSaving || isDeletingWeek)
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

    // Actions: load, publish, edit, delete
    private func loadWeeks() async {
        errorMessage = nil
        successMessage = nil

        guard let studentId = student.id, !studentId.isEmpty else {
            vm.errorMessage = "Aluno inválido: id não encontrado."
            return
        }

        await vm.loadWeeks(studentId: studentId)
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
        isEditSheetOpen = false
    }

    private func deleteWeekMessageText() -> String {
        guard let w = weekPendingDelete else { return "Tem certeza que deseja excluir esta semana?" }
        return "A semana \"\(w.weekTitle)\" será excluída (dias e progresso também)."
    }

    private func confirmDeleteWeek() async {
        errorMessage = nil
        successMessage = nil

        guard !isDeletingWeek else { return }
        guard let week = weekPendingDelete, let weekId = week.id, !weekId.isEmpty else { return }

        isDeletingWeek = true
        defer { isDeletingWeek = false }

        do {
            try await FirestoreRepository.shared.deleteTrainingWeekCascade(weekId: weekId)
            successMessage = "Semana excluída com sucesso."
            weekPendingDelete = nil
            await loadWeeks()
        } catch {
            errorMessage = (error as NSError).localizedDescription
            weekPendingDelete = nil
        }
    }

    /// ✅ Fluxo "NOVA SEMANA" - botão Publicar
    private func publishWeek() async {
        errorMessage = nil
        successMessage = nil

        guard !isSaving else { return }

        guard let studentId = student.id, !studentId.isEmpty else {
            errorMessage = "Aluno inválido: id não encontrado."
            return
        }

        let trimmedTitle = weekTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Informe o título da semana."
            return
        }

        guard let teacherId = Auth.auth().currentUser?.uid, !teacherId.isEmpty else {
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let now = Date()

            _ = try await FirestoreRepository.shared.createWeekForStudent(
                studentId: studentId,
                teacherId: teacherId,
                title: trimmedTitle,
                categoryRaw: category.rawValue,
                startDate: now,
                endDate: now,
                isPublished: true
            )

            weekTitle = ""
            successMessage = "Semana publicada com sucesso."
            await loadWeeks()

        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
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
