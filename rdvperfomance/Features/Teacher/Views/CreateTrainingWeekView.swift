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
    @Environment(\.locale) private var locale

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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { pop() } label: {
                    ZStack {
                        Color.clear
                            .frame(width: 44, height: 44)

                        Image(systemName: "chevron.left")
                            .foregroundColor(.green)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("ui.publish_week")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            ToolbarItemGroup(placement: .topBarTrailing) {

                Button {
                    Task { await loadWeeks() }
                } label: {
                    ZStack {
                        Color.clear
                            .frame(width: 44, height: 44)

                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.green)
                    }
                    .contentShape(Rectangle())
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
        .alert("ui.delete_week_2", isPresented: $showDeleteWeekConfirm) {
            Button("common.cancel", role: .cancel) {
                weekPendingDelete = nil
            }
            Button("common.delete", role: .destructive) {
                Task { await confirmDeleteWeek() }
            }
        } message: {
            Text(deleteWeekMessageText())
        }
    }

    // Header com contexto do aluno e categoria
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            let format = AppLocalization.string("ui.student_value", locale: locale)
            Text(String(format: format, locale: locale, arguments: [student.name]))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.70))

            Text("ui.you_can_view_registered_weeks_edit_the_title_and_add_days")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Card que exibe semanas existentes
    private var weeksCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("ui.registered_weeks")
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
                Text("ui.no_week_registered_for_this_student")
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

                    Group {
                        if week.isPublished {
                            Text("ui.published")
                        } else {
                            Text("ui.draft")
                        }
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(week.isPublished ? .green.opacity(0.85) : .white.opacity(0.45))
                }

                Spacer()

                // Menu de ações por semana
                Menu {
                    Button {
                        openEditWeekTitle(week)
                    } label: {
                        Label(LocalizedStringKey("ui.edit_title"), systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        weekPendingDelete = week
                        showDeleteWeekConfirm = true
                    } label: {
                        Label(LocalizedStringKey("ui.delete_week"), systemImage: "trash")
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
                    Text("ui.view_days")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color.white.opacity(0.10))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)

                Button { openAddDay(week) } label: {
                    Text("ui.add_days")
                        .padding(.horizontal, 12)
                        .primaryGreenActionButton()
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(.vertical, 12)
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("ui.new_week")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.35))

            UnderlineTextField(
                title: "ui.week_title",
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
                        Text("ui.publish")
                    }
                    Spacer()
                }
                .primaryGreenActionButton()
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
            vm.errorMessage = AppLocalization.string("ui.invalid_student_id_not_found", locale: locale)
            return
        }
        guard let teacherId = Auth.auth().currentUser?.uid, !teacherId.isEmpty else {
            vm.errorMessage = AppLocalization.string("ui.unable_to_identify_the_signed_in_trainer", locale: locale)
            return
        }

        await vm.loadWeeks(
            studentId: studentId,
            teacherId: teacherId,
            categoryRaw: category.rawValue
        )
    }

    private func openWeekDays(_ week: TrainingWeekFS) {
        guard let weekId = week.id, !weekId.isEmpty else { return }
        guard let studentId = student.id, !studentId.isEmpty else { return }
        path.append(
            .studentWorkouts(
                studentId: studentId,
                studentName: student.name,
                initialExpandedWeekId: weekId
            )
        )
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

                Text("ui.edit_week_title")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                UnderlineTextField(
                    title: "ui.new_title",
                    text: $editingTitle,
                    isSecure: false,
                    showPassword: $showPasswordDummy,
                    lineColor: Theme.Colors.divider,
                    textColor: .white.opacity(0.92),
                    placeholderColor: .white.opacity(0.55)
                )

                HStack(spacing: 10) {
                    Button { isEditSheetOpen = false } label: {
                        Text("common.cancel")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.90))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.10))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button { Task { await saveEditedTitle() } } label: {
                        Text("common.save")
                            .padding(.horizontal, 14)
                            .primaryGreenActionButton()
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
        // ✅ Corrige o "Editar título": valida, salva no Firestore e recarrega a lista
        await MainActor.run {
            errorMessage = nil
            successMessage = nil
        }

        guard let week = editingWeek, let weekId = week.id, !weekId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run {
                errorMessage = AppLocalization.string("ui.unable_to_edit_invalid_week", locale: locale)
            }
            return
        }

        let trimmed = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await MainActor.run {
                errorMessage = AppLocalization.string("ui.enter_a_valid_title", locale: locale)
            }
            return
        }

        // Opcional: evita escrita desnecessária se não mudou
        if trimmed == week.weekTitle {
            await MainActor.run {
                isEditSheetOpen = false
                editingWeek = nil
            }
            return
        }

        do {
            try await FirestoreRepository.shared.updateWeekTitle(weekId: weekId, newTitle: trimmed)

            await MainActor.run {
                successMessage = AppLocalization.string("ui.title_updated_successfully", locale: locale)
                isEditSheetOpen = false
                editingWeek = nil
            }

            await loadWeeks()

        } catch {
            await MainActor.run {
                errorMessage = (error as NSError).localizedDescription
            }
        }
    }

    private func deleteWeekMessageText() -> String {
        guard let w = weekPendingDelete else {
            return AppLocalization.string("ui.are_you_sure_you_want_to_delete_this_week", locale: locale)
        }
        let format = AppLocalization.string("ui.week_will_be_deleted",
            locale: locale
        )
        return String(format: format, locale: locale, arguments: [w.weekTitle])
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
            successMessage = AppLocalization.string("ui.week_deleted_successfully", locale: locale)
            weekPendingDelete = nil
            await loadWeeks()
        } catch {
            errorMessage = (error as NSError).localizedDescription
            weekPendingDelete = nil
        }
    }

    // Publica nova semana no Firestore
    private func publishWeek() async {
        errorMessage = nil
        successMessage = nil

        guard !isSaving else { return }

        guard let studentId = student.id, !studentId.isEmpty else {
            errorMessage = AppLocalization.string("ui.invalid_student_id_not_found", locale: locale)
            return
        }

        let trimmedTitle = weekTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = AppLocalization.string("ui.enter_the_week_title", locale: locale)
            return
        }

        guard let teacherId = Auth.auth().currentUser?.uid, !teacherId.isEmpty else {
            errorMessage = AppLocalization.string("ui.unable_to_identify_the_signed_in_trainer", locale: locale)
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
            successMessage = AppLocalization.string("ui.week_published_successfully", locale: locale)
            await loadWeeks()

        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }

    private func weekDateRangeText(_ week: TrainingWeekFS) -> String? {
        guard let s = week.startDate, let e = week.endDate else { return nil }
        let f = DateFormatter()
        f.locale = locale
        f.setLocalizedDateFormatFromTemplate("ddMMyyyy")
        let format = AppLocalization.string("ui.value_value", locale: locale)
        return String(
            format: format,
            locale: locale,
            arguments: [f.string(from: s), f.string(from: e)]
        )
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
