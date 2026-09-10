import SwiftUI
import FirebaseAuth

struct TeacherSendWorkoutView: View {

    private enum Step: Equatable {
        case student
        case workout
        case day
    }

    private struct AvailableDay: Identifiable {
        let weekId: String
        let dayIndex: Int
        let date: Date

        var id: String {
            "\(weekId)-\(dayIndex)"
        }
    }

    @Binding var path: [AppRoute]
    let category: TreinoTipo

    @State private var students: [AppUser] = []
    @State private var studentCategories: [String: [TreinoTipo]] = [:]
    @State private var templates: [WorkoutTemplateFS] = []
    @State private var weeks: [TrainingWeekFS] = []
    @State private var searchText: String = ""

    @State private var selectedStudent: AppUser?
    @State private var selectedTemplate: WorkoutTemplateFS?
    @State private var selectedDay: AvailableDay?
    @State private var step: Step = .student

    @State private var isLoadingInitialData = false
    @State private var isLoadingWeeks = false
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    private let contentMaxWidth: CGFloat = 380
    private let dayOptions = Array(0...6)

    private var filteredStudents: [AppUser] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return students }
        return students.filter {
            $0.name.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    private var canAdvanceFromStudent: Bool {
        selectedStudent != nil && !isLoadingWeeks
    }

    private var canAdvanceFromWorkout: Bool {
        selectedStudent != nil && selectedTemplate != nil
    }

    private var canSend: Bool {
        selectedStudent != nil && selectedTemplate != nil && selectedDay != nil && !isSending
    }

    private var availableDays: [AvailableDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var daysByDate: [Date: AvailableDay] = [:]

        for week in weeks {
            guard let weekId = week.id?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !weekId.isEmpty,
                  let startDate = week.startDate else {
                continue
            }

            for dayIndex in dayOptions {
                guard let date = calendar.date(byAdding: .day, value: dayIndex, to: startDate) else {
                    continue
                }
                let normalizedDate = calendar.startOfDay(for: date)
                guard normalizedDate >= today, daysByDate[normalizedDate] == nil else {
                    continue
                }
                daysByDate[normalizedDate] = AvailableDay(
                    weekId: weekId,
                    dayIndex: dayIndex,
                    date: normalizedDate
                )
            }
        }

        return daysByDate.values.sorted { $0.date < $1.date }
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
                            stepIndicator

                            switch step {
                            case .student:
                                studentSection
                                nextButton(enabled: canAdvanceFromStudent) {
                                    step = .workout
                                }
                            case .workout:
                                selectedStudentSummary
                                templateSection
                                nextButton(enabled: canAdvanceFromWorkout) {
                                    step = .day
                                }
                            case .day:
                                selectedWorkoutSummary
                                daySection
                                sendButton
                            }

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
                Button { goBack() } label: {
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
                Text(step == .day ? "Selecionar dia" : "Enviar treino")
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

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            stepItem(number: 1, title: "Aluno", isActive: step == .student, isComplete: step != .student)
            Rectangle().fill(Theme.Colors.divider).frame(height: 1)
            stepItem(number: 2, title: "Treino", isActive: step == .workout, isComplete: step == .day)
            Rectangle().fill(Theme.Colors.divider).frame(height: 1)
            stepItem(number: 3, title: "Dia", isActive: step == .day, isComplete: false)
        }
    }

    private func stepItem(number: Int, title: String, isActive: Bool, isComplete: Bool) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill((isActive || isComplete) ? Color.green.opacity(0.18) : Color.white.opacity(0.10))
                    .frame(width: 26, height: 26)
                Text("\(number)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor((isActive || isComplete) ? .green : .white.opacity(0.55))
            }
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor((isActive || isComplete) ? .white.opacity(0.92) : .white.opacity(0.55))
        }
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
                studentsList
            }
        }
    }

    private var studentsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(filteredStudents.enumerated()), id: \.element.id) { index, student in
                Button {
                    select(student)
                } label: {
                    HStack(spacing: 14) {
                        StudentAvatarView(base64: student.photoBase64, size: 28)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(student.name)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.92))
                            Text("Categoria: \(studentCategoryText(student))")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.55))
                        }

                        Spacer()

                        Image(systemName: selectedStudent?.id == student.id ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(selectedStudent?.id == student.id ? .green : .white.opacity(0.35))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)

                if index < filteredStudents.count - 1 {
                    Divider()
                        .background(Theme.Colors.divider)
                        .padding(.leading, 54)
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

    private var selectedStudentSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Aluno selecionado")
            if let selectedStudent {
                HStack(spacing: 12) {
                    StudentAvatarView(base64: selectedStudent.photoBase64, size: 28)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(selectedStudent.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.92))
                        Text("Categoria: \(studentCategoryText(selectedStudent))")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.55))
                    }
                }
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

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Selecionar treino")

            templatePicker(category: .crossfit, title: "Crossfit")
            templatePicker(category: .academia, title: "Academia")
            templatePicker(category: .emCasa, title: "Treinos em Casa")
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

    private func templatePicker(category: TreinoTipo, title: String) -> some View {
        let categoryTemplates = templates.filter {
            TreinoTipo.normalized(from: $0.categoryRaw) == category
        }
        let selection = selectedTemplate.flatMap {
            TreinoTipo.normalized(from: $0.categoryRaw) == category ? $0 : nil
        }

        return VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))

            if isLoadingInitialData {
                pickerPlaceholder("Carregando treinos...")
            } else if categoryTemplates.isEmpty {
                pickerPlaceholder("Nenhum treino cadastrado.")
            } else {
                Menu {
                    ForEach(categoryTemplates) { template in
                        Button(templateMenuTitle(template)) {
                            selectedTemplate = template
                            clearMessages()
                        }
                    }
                } label: {
                    pickerLabel(selection?.title ?? "Selecionar treino")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var selectedWorkoutSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Treino selecionado")
            if let selectedTemplate {
                Text(selectedTemplate.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                Text(TreinoTipo.normalized(from: selectedTemplate.categoryRaw)?.displayName ?? selectedTemplate.categoryRaw)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
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

    private var daySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Selecionar dia")

            if isLoadingWeeks {
                loadingRow("Carregando dias disponíveis...")
            } else if availableDays.isEmpty {
                emptyRow("Este aluno não possui dias disponíveis a partir de hoje.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(availableDays.enumerated()), id: \.element.id) { index, day in
                        Button {
                            selectedDay = day
                            clearMessages()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedDay?.id == day.id ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(selectedDay?.id == day.id ? .green : .white.opacity(0.35))
                                Text(weekdayTitle(for: day.date))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.92))
                                Spacer()
                                Text(dateTitle(for: day.date))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.55))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)

                        if index < availableDays.count - 1 {
                            Divider()
                                .background(Theme.Colors.divider)
                                .padding(.leading, 48)
                        }
                    }
                }
                .background(Color.white.opacity(0.10))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
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

    private func nextButton(enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Próximo")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.green.opacity(enabled ? 0.16 : 0.08))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(enabled ? 0.35 : 0.15), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
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
        HStack {
            Text(title)
                .foregroundColor(.white.opacity(0.35))
            Spacer()
            Image(systemName: "chevron.down")
                .foregroundColor(.white.opacity(0.25))
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
            .joined(separator: " / ")
    }

    private func templateMenuTitle(_ template: WorkoutTemplateFS) -> String {
        "\(template.title) • \(template.sectionKey)"
    }

    private func weekdayTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date).capitalized(with: formatter.locale)
    }

    private func dateTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
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
        selectedDay = nil
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
        defer {
            if selectedStudent?.id == studentId {
                isLoadingWeeks = false
            }
        }

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
    }

    private func sendTemplateToSelectedDay() async {
        clearMessages()

        guard let template = selectedTemplate else {
            errorMessage = "Selecione um treino válido."
            return
        }
        guard let selectedDay else {
            errorMessage = "Selecione um dia válido."
            return
        }

        let dayName = "Dia \(selectedDay.dayIndex + 1)"
        isSending = true
        defer { isSending = false }

        do {
            let blocks = template.blocks ?? []
            _ = try await FirestoreRepository.shared.upsertDay(
                weekId: selectedDay.weekId,
                dayId: nil,
                dayIndex: selectedDay.dayIndex,
                dayName: dayName,
                date: selectedDay.date,
                title: template.title,
                description: template.description,
                blocks: blocks
            )
            successMessage = "Treino enviado com sucesso!"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    private func goBack() {
        switch step {
        case .student:
            guard !path.isEmpty else { return }
            path.removeLast()
        case .workout:
            step = .student
        case .day:
            step = .workout
        }
    }
}
