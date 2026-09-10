import SwiftUI
import FirebaseAuth

struct TeacherSendWorkoutView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo

    @State private var students: [AppUser] = []
    @State private var studentCategories: [String: [TreinoTipo]] = [:]
    @State private var templates: [WorkoutTemplateFS] = []
    @State private var weeks: [TrainingWeekFS] = []
    @State private var searchText: String = ""

    @State private var selectedStudent: AppUser?
    @State private var selectedTemplate: WorkoutTemplateFS?
    @State private var selectedWeek: TrainingWeekFS?
    @State private var selectedDayIndex: Int?

    @State private var isLoadingInitialData: Bool = false
    @State private var isLoadingWeeks: Bool = false
    @State private var isSending: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    private let contentMaxWidth: CGFloat = 380
    private let dayOptions = Array(0...6)

    private var filteredStudents: [AppUser] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return students }
        return students.filter {
            $0.name.range(of: query, options: .caseInsensitive) != nil
        }
    }

    private var canSend: Bool {
        selectedStudent != nil
            && selectedTemplate != nil
            && selectedWeek?.id?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            && selectedDayIndex != nil
            && !isSending
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
                            studentSection
                            templateSection
                            destinationSection
                            sendButton

                            if let errorMessage {
                                TeacherWorkoutTemplatesMessageCard(text: errorMessage, isError: true)
                            }

                            if let successMessage {
                                TeacherWorkoutTemplatesMessageCard(text: successMessage, isError: false)
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
                        Color.clear.frame(width: 44, height: 44)
                        Image(systemName: "chevron.left")
                            .foregroundColor(.green)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("Enviar treino")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await bootstrap() }
    }

    private var studentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Selecionar aluno")

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.55))
                TextField("Buscar aluno...", text: $searchText)
                    .foregroundColor(.white.opacity(0.92))
                    .tint(.green)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.10))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )

            if isLoadingInitialData {
                loadingRow("Carregando alunos...")
            } else if filteredStudents.isEmpty {
                emptyRow(searchText.isEmpty ? "Nenhum aluno vinculado." : "Nenhum aluno encontrado.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filteredStudents.enumerated()), id: \.element.id) { index, student in
                        studentRow(student)
                        if index < filteredStudents.count - 1 {
                            Divider()
                                .background(Theme.Colors.divider)
                                .padding(.leading, 42)
                        }
                    }
                }
                .background(Theme.Colors.cardBackground)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
        }
    }

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle("Selecionar treino")

            if isLoadingInitialData {
                pickerPlaceholder("Carregando treinos...")
            } else if templates.isEmpty {
                pickerPlaceholder("Nenhum treino cadastrado.")
            } else {
                Menu {
                    ForEach(templates) { template in
                        Button(templateMenuTitle(template)) {
                            selectedTemplate = template
                            clearMessages()
                        }
                    }
                } label: {
                    pickerLabel(selectedTemplate.map(templateMenuTitle) ?? "Selecionar treino")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var destinationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Destino do treino")

            VStack(alignment: .leading, spacing: 6) {
                Text("Semana")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))

                if selectedStudent == nil {
                    pickerPlaceholder("Selecione um aluno primeiro")
                } else if isLoadingWeeks {
                    pickerPlaceholder("Carregando semanas...")
                } else if weeks.isEmpty {
                    Button {
                        errorMessage = "O aluno deve ter uma semana cadastrada."
                        successMessage = nil
                    } label: {
                        pickerLabel("Selecionar semana")
                    }
                    .buttonStyle(.plain)
                } else {
                    Menu {
                        ForEach(weeks) { week in
                            Button(week.weekTitle) {
                                selectedWeek = week
                                selectedDayIndex = nil
                                clearMessages()
                            }
                        }
                    } label: {
                        pickerLabel(selectedWeek?.weekTitle ?? "Selecionar semana")
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Dia")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))

                Picker("Dia", selection: daySelection) {
                    Text("Selecionar dia").tag(nil as Int?)
                    ForEach(dayOptions, id: \.self) { dayIndex in
                        Text("Dia \(dayIndex + 1)").tag(dayIndex as Int?)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(selectedWeek == nil)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var sendButton: some View {
        Button {
            Task { await sendTemplateToSelectedDay() }
        } label: {
            HStack {
                Spacer()
                if isSending {
                    ProgressView().tint(.white)
                } else {
                    Text("Enviar treino")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                }
                Spacer()
            }
            .padding(.vertical, 14)
            .background(Color.green.opacity(canSend ? 0.16 : 0.08))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(canSend ? 0.35 : 0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canSend)
    }

    private var daySelection: Binding<Int?> {
        Binding(
            get: { selectedDayIndex },
            set: {
                selectedDayIndex = $0
                clearMessages()
            }
        )
    }

    private func studentRow(_ student: AppUser) -> some View {
        Button {
            select(student)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedStudent?.id == student.id ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedStudent?.id == student.id ? .green : .white.opacity(0.35))
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: 3) {
                    Text(student.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))

                    Text(studentCategoryText(student))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white.opacity(0.92))
    }

    private func pickerLabel(_ title: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.white.opacity(0.92))
                .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.down")
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.10))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func pickerPlaceholder(_ title: String) -> some View {
        pickerLabel(title)
            .foregroundColor(.white.opacity(0.35))
            .allowsHitTesting(false)
    }

    private func loadingRow(_ title: String) -> some View {
        HStack(spacing: 10) {
            ProgressView()
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.vertical, 10)
    }

    private func emptyRow(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.55))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
    }

    private func studentCategoryText(_ student: AppUser) -> String {
        guard let studentId = student.id else { return "" }
        return (studentCategories[studentId] ?? [])
            .map(\.displayName)
            .joined(separator: " • ")
    }

    private func templateMenuTitle(_ template: WorkoutTemplateFS) -> String {
        let categoryName = TreinoTipo.normalized(from: template.categoryRaw)?.displayName ?? template.categoryRaw
        return "\(template.title) • \(categoryName)"
    }

    private func bootstrap() async {
        errorMessage = nil
        successMessage = nil

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }

        isLoadingInitialData = true
        defer { isLoadingInitialData = false }

        do {
            async let groupedStudents = FirestoreRepository.shared.getStudentsGroupedByTeacher(teacherId: teacherId)
            async let fetchedTemplates = FirestoreRepository.shared.getWorkoutTemplatesForTeacher(teacherId: teacherId)
            let (studentsByCategory, loadedTemplates) = try await (groupedStudents, fetchedTemplates)

            var usersById: [String: AppUser] = [:]
            var categoriesByStudent: [String: Set<TreinoTipo>] = [:]
            for (studentCategory, categoryStudents) in studentsByCategory {
                for student in categoryStudents {
                    guard let studentId = student.id,
                          !studentId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        continue
                    }
                    usersById[studentId] = student
                    categoriesByStudent[studentId, default: []].insert(studentCategory)
                }
            }

            students = usersById.values.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            studentCategories = categoriesByStudent.mapValues {
                $0.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
            }
            templates = loadedTemplates
        } catch {
            errorMessage = error.localizedDescription
            students = []
            studentCategories = [:]
            templates = []
        }
    }

    private func select(_ student: AppUser) {
        guard selectedStudent?.id != student.id else { return }
        selectedStudent = student
        selectedWeek = nil
        selectedDayIndex = nil
        weeks = []
        clearMessages()
        Task { await loadWeeksForSelectedStudent() }
    }

    private func loadWeeksForSelectedStudent() async {
        guard let studentId = selectedStudent?.id?.trimmingCharacters(in: .whitespacesAndNewlines),
              !studentId.isEmpty else {
            return
        }

        isLoadingWeeks = true

        do {
            let loadedWeeks = try await FirestoreRepository.shared.getWeeksForStudent(
                studentId: studentId,
                onlyPublished: false
            )
            guard selectedStudent?.id == studentId else { return }
            weeks = loadedWeeks
        } catch {
            guard selectedStudent?.id == studentId else { return }
            errorMessage = error.localizedDescription
            weeks = []
        }

        isLoadingWeeks = false
    }

    private func sendTemplateToSelectedDay() async {
        clearMessages()

        guard let template = selectedTemplate else {
            errorMessage = "Selecione um treino válido."
            return
        }
        guard let weekId = selectedWeek?.id?.trimmingCharacters(in: .whitespacesAndNewlines),
              !weekId.isEmpty else {
            errorMessage = "Selecione uma semana válida."
            return
        }
        guard let selectedDayIndex else {
            errorMessage = "Selecione um dia válido."
            return
        }

        let base = weekStartDate(selectedWeek) ?? Date()
        let date = Calendar.current.date(byAdding: .day, value: selectedDayIndex, to: base) ?? base
        let dayName = "Dia \(selectedDayIndex + 1)"

        isSending = true
        defer { isSending = false }

        do {
            let blocks = template.blocks ?? []
            _ = try await FirestoreRepository.shared.upsertDay(
                weekId: weekId,
                dayId: nil,
                dayIndex: selectedDayIndex,
                dayName: dayName,
                date: date,
                title: template.title,
                description: template.description,
                blocks: blocks
            )
            successMessage = "Treino enviado com sucesso!"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func weekStartDate(_ week: TrainingWeekFS?) -> Date? {
        week?.startDate
    }

    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
