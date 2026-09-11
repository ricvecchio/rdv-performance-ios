import SwiftUI
import FirebaseAuth

struct TeacherSendWorkoutView: View {

    private enum Step: Equatable {
        case student
        case workout
        case day
    }

    private struct AvailableDay: Identifiable {
        let date: Date

        var id: Date { date }
    }

    @Binding var path: [AppRoute]
    let category: TreinoTipo
    let preselectedStudentID: String?
    let startsAtWorkout: Bool

    @State private var students: [AppUser] = []
    @State private var studentCategories: [String: [TreinoTipo]] = [:]
    @State private var templates: [WorkoutTemplateFS] = []
    @State private var searchText: String = ""

    @State private var selectedStudentIDs: Set<String> = []
    @State private var selectedTemplates: [TreinoTipo: WorkoutTemplateFS] = [:]
    @State private var selectedDay: AvailableDay?
    @State private var step: Step = .student

    @State private var isLoadingInitialData = false
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    private let contentMaxWidth: CGFloat = 380

    init(
        path: Binding<[AppRoute]>,
        category: TreinoTipo,
        preselectedStudentID: String? = nil,
        startsAtWorkout: Bool = false
    ) {
        self._path = path
        self.category = category
        let studentID = preselectedStudentID?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        self.preselectedStudentID = studentID?.isEmpty == false ? studentID : nil
        self.startsAtWorkout = startsAtWorkout && self.preselectedStudentID != nil
        _selectedStudentIDs = State(initialValue: self.preselectedStudentID.map { [$0] } ?? [])
        _step = State(initialValue: self.startsAtWorkout ? .workout : .student)
    }

    private var filteredStudents: [AppUser] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return students }
        return students.filter {
            $0.name.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    private var selectedStudents: [AppUser] {
        students.filter {
            guard let studentId = $0.id else { return false }
            return selectedStudentIDs.contains(studentId)
        }
    }

    private var selectedTemplatesInOrder: [(category: TreinoTipo, template: WorkoutTemplateFS)] {
        [.crossfit, .academia, .emCasa].compactMap { category in
            selectedTemplates[category].map { (category, $0) }
        }
    }

    private var currentWeekDays: [AvailableDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let daysUntilSunday = (8 - calendar.component(.weekday, from: today)) % 7

        return (0...daysUntilSunday).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else {
                return nil
            }
            return AvailableDay(date: date)
        }
    }

    private var canAdvanceFromStudent: Bool {
        !selectedStudentIDs.isEmpty
    }

    private var canAdvanceFromWorkout: Bool {
        !selectedStudentIDs.isEmpty && !selectedTemplates.isEmpty
    }

    private var canSend: Bool {
        selectedDay != nil
            && !selectedStudentIDs.isEmpty
            && !selectedTemplates.isEmpty
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
                            stepIndicator

                            switch step {
                            case .student:
                                studentSection
                                nextButton(enabled: canAdvanceFromStudent) {
                                    step = .workout
                                }
                            case .workout:
                                selectedStudentsSummary
                                templateSection
                                nextButton(enabled: canAdvanceFromWorkout) {
                                    Task { await advanceToDaySelection() }
                                }
                            case .day:
                                selectedWorkoutsSummary
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
            sectionTitle("Selecionar alunos")
            studentSearchField
            studentListContent
        }
    }

    private var studentSearchField: some View {
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
    }

    @ViewBuilder
    private var studentListContent: some View {
        if isLoadingInitialData {
            loadingRow("Carregando alunos...")
        } else if filteredStudents.isEmpty {
            emptyRow(
                searchText.isEmpty
                    ? "Nenhum aluno vinculado."
                    : "Nenhum aluno encontrado."
            )
        } else {
            studentsList
        }
    }

    private var studentsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(filteredStudents.enumerated()), id: \.element.id) { index, student in
                Button {
                    toggleSelection(for: student)
                } label: {
                    studentRow(student)
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
        .disabled(isSending)
    }

    private func studentRow(_ student: AppUser) -> some View {
        let selected = isSelected(student)
        let selectionIcon = selected ? "checkmark.circle.fill" : "circle"
        let selectionColor: Color = selected ? .green : .white.opacity(0.35)

        return HStack(spacing: 14) {
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

            Image(systemName: selectionIcon)
                .font(.system(size: 20))
                .foregroundColor(selectionColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var selectedStudentsSummary: some View {
        VStack(spacing: 0) {
            cardSectionTitle("Alunos selecionados")

            VStack(alignment: .leading, spacing: 8) {
                ForEach(selectedStudents) { student in
                    Text(student.name)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .disabled(isSending)
    }

    private var templateSection: some View {
        VStack(spacing: 0) {
            cardSectionTitle("Selecionar treino")

            VStack(alignment: .leading, spacing: 12) {
                templatePicker(category: .crossfit, title: "Crossfit")
                templatePicker(category: .academia, title: "Academia")
                templatePicker(category: .emCasa, title: "Treinos em Casa")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
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
        let selection = selectedTemplates[category]

        return VStack(alignment: .leading, spacing: 6) {
            categoryHeader(category: category, title: title)
            templatePickerContent(
                category: category,
                templates: categoryTemplates,
                selection: selection
            )
        }
    }

    private func categoryHeader(category: TreinoTipo, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: categoryIcon(for: category))
                .font(.system(size: 14))
                .foregroundColor(.green.opacity(0.85))

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
    }

    @ViewBuilder
    private func templatePickerContent(
        category: TreinoTipo,
        templates: [WorkoutTemplateFS],
        selection: WorkoutTemplateFS?
    ) -> some View {
        if isLoadingInitialData {
            pickerPlaceholder("Carregando treinos...")
        } else if templates.isEmpty {
            pickerPlaceholder("Nenhum treino cadastrado.")
        } else {
            Menu {
                ForEach(templates) { template in
                    Button(templateMenuTitle(template)) {
                        selectedTemplates[category] = template
                        clearMessages()
                    }
                }
            } label: {
                pickerLabel(
                    selection?.title ?? "Selecionar treino",
                    isSelected: selection != nil
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var selectedWorkoutsSummary: some View {
        VStack(spacing: 0) {
            cardSectionTitle("Treinos selecionados")

            VStack(alignment: .leading, spacing: 12) {
                ForEach(selectedTemplatesInOrder, id: \.category) { item in
                    selectedWorkoutRow(category: item.category, template: item.template)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func selectedWorkoutRow(
        category: TreinoTipo,
        template: WorkoutTemplateFS
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(category.displayName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.55))
            Text(template.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
        }
    }

    private var daySection: some View {
        VStack(spacing: 0) {
            cardSectionTitle("Selecionar dia")

            VStack(spacing: 0) {
                ForEach(Array(currentWeekDays.enumerated()), id: \.element.id) { index, day in
                    Button {
                        selectedDay = day
                        clearMessages()
                    } label: {
                        dayRow(day: day, isSelected: selectedDay?.id == day.id)
                    }
                    .buttonStyle(.plain)

                    if index < currentWeekDays.count - 1 {
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
            .disabled(isSending)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func dayRow(day: AvailableDay, isSelected: Bool) -> some View {
        let selectionIcon = isSelected ? "checkmark.circle.fill" : "circle"
        let selectionColor: Color = isSelected ? .green : .white.opacity(0.35)

        return HStack(spacing: 12) {
            Image(systemName: selectionIcon)
                .font(.system(size: 20))
                .foregroundColor(selectionColor)
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

    private func nextButton(enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            nextButtonContent
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private var sendButton: some View {
        Button {
            Task { await sendTemplatesToSelectedDay() }
        } label: {
            sendButtonContent
        }
        .buttonStyle(.plain)
        .disabled(!canSend)
    }

    private var nextButtonContent: some View {
        HStack {
            Spacer()
            Text("Próximo")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
            Spacer()
        }
        .modifier(PrimaryActionButtonStyle())
    }

    private var sendButtonContent: some View {
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
        .modifier(PrimaryActionButtonStyle())
    }

    private struct PrimaryActionButtonStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding(.vertical, 14)
                .background(Color.green.opacity(0.16))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.35), lineWidth: 1)
                )
        }
    }

    private func pickerLabel(_ title: String, isSelected: Bool) -> some View {
        let backgroundColor: Color = isSelected
            ? Color.green.opacity(0.14)
            : Color.white.opacity(0.10)
        let borderColor: Color = isSelected
            ? Color.green.opacity(0.35)
            : Color.white.opacity(0.12)

        return HStack {
            Text(title)
                .foregroundColor(.white.opacity(0.92))
                .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.down")
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white.opacity(0.92))
    }

    private func cardSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.35))
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func categoryIcon(for category: TreinoTipo) -> String {
        switch category {
        case .crossfit:
            return "figure.strengthtraining.traditional"
        case .academia:
            return "dumbbell"
        case .emCasa:
            return "house.fill"
        }
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

    private func isSelected(_ student: AppUser) -> Bool {
        guard let studentId = student.id else { return false }
        return selectedStudentIDs.contains(studentId)
    }

    private func toggleSelection(for student: AppUser) {
        guard let studentId = student.id?.trimmingCharacters(in: .whitespacesAndNewlines),
              !studentId.isEmpty else {
            return
        }

        if selectedStudentIDs.contains(studentId) {
            selectedStudentIDs.remove(studentId)
        } else {
            selectedStudentIDs.insert(studentId)
        }
        selectedDay = nil
        clearMessages()
    }

    private func advanceToDaySelection() async {
        guard canAdvanceFromWorkout else { return }
        step = .day
        selectedDay = nil
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

    private func sendTemplatesToSelectedDay() async {
        clearMessages()

        guard let selectedDay else { return }

        isSending = true
        defer { isSending = false }

        do {
            let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !teacherId.isEmpty else {
                errorMessage = "Não foi possível identificar o professor logado."
                return
            }

            let calendar = Calendar.current
            let selectedDate = calendar.startOfDay(for: selectedDay.date)
            for studentId in selectedStudentIDs {
                let week = try await FirestoreRepository.shared.resolveOrCreateWeekForStudent(
                    studentId: studentId,
                    teacherId: teacherId,
                    categoryRaw: category.rawValue,
                    date: selectedDate
                )
                guard let dayIndex = calendar.dateComponents(
                    [.day],
                    from: week.startDate,
                    to: selectedDate
                ).day,
                (0...6).contains(dayIndex) else {
                    throw FirestoreRepositoryError.invalidData
                }
                let dayName = weekdayTitle(for: selectedDate)

                for (_, template) in selectedTemplatesInOrder {
                    let blocks = template.blocks ?? []
                    _ = try await FirestoreRepository.shared.upsertDay(
                        weekId: week.weekId,
                        dayId: nil,
                        dayIndex: dayIndex,
                        dayName: dayName,
                        date: selectedDate,
                        title: template.title,
                        description: template.description,
                        blocks: blocks
                    )
                }
            }
            successMessage = "Treino enviado com sucesso!"
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            path.removeAll()
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
            if startsAtWorkout {
                guard !path.isEmpty else { return }
                path.removeLast()
            } else {
                step = .student
            }
        case .day:
            step = .workout
        }
    }
}
