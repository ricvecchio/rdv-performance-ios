import SwiftUI
import FirebaseAuth

private struct WorkoutSectionOption: Identifiable, Hashable {
    let title: String
    let sectionKey: String

    var id: String { sectionKey }
}

private struct WorkoutPickerLabel: View {
    let title: DisplayText
    let isSelected: Bool
    @Environment(\.appTheme) private var appTheme

    var body: some View {
        // Tema Claro: selecionado em verde militar translúcido (padrão do botão Sair) com texto/ícone brancos;
        // sem seleção em cinza claro (mesmos tons do botão Próximo desabilitado) com texto/ícone escuros.
        let isLightSelected = appTheme == .light && isSelected
        let isLightUnselected = appTheme == .light && !isSelected
        let borderColor: AnyShapeStyle = isLightSelected
            ? AnyShapeStyle(AppThemePalette.lightBar.opacity(0.90))
            : isLightUnselected
                ? AnyShapeStyle(Theme.Colors.ink(0.12))
                : isSelected
                    ? AnyShapeStyle(Theme.Colors.primaryGreen.opacity(0.35))
                    : AnyShapeStyle(Theme.Colors.primaryGreen.opacity(0.28))

        HStack {
            title.view()
                .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(isLightSelected ? AnyShapeStyle(Color.white) : AnyShapeStyle(Theme.Colors.ink(0.92)))
            .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.down")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(
                    isLightSelected
                        ? AnyShapeStyle(Color.white)
                        : isLightUnselected
                            ? AnyShapeStyle(Theme.Colors.ink(0.70))
                            : AnyShapeStyle(Theme.Colors.icon(isSelected ? Theme.Colors.primaryGreen.opacity(0.85) : .white.opacity(0.25)))
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            isLightSelected
                ? AnyShapeStyle(AppThemePalette.lightBar.opacity(0.80))
                : isLightUnselected
                    ? AnyShapeStyle(Theme.Colors.ink(0.10))
                    : AnyShapeStyle(Theme.Colors.glass(0.68))
        )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}

// Tema Claro (habilitado): cores do botão Sair da ProfileView com as mesmas medidas do `primaryGreenActionButton()`.
// Tema Escuro e estado desabilitado: mantém exatamente o `primaryGreenActionButton()` original.
private struct LightMilitaryActionButtonModifier: ViewModifier {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        if appTheme == .light && isEnabled {
            content
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.vertical, 14)
                .background(AppThemePalette.lightBar.opacity(0.80))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppThemePalette.lightBar.opacity(0.90), lineWidth: 1)
                )
        } else {
            content.primaryGreenActionButton()
        }
    }
}

struct TeacherSendWorkoutView: View {
    @Environment(\.locale) private var locale
    @Environment(\.appTheme) private var appTheme

    // Paleta do Tema Claro (mesmos valores da `LightColors` da TrainingWeeksView)
    private enum LightColors {
        static let cardSurface = Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)  // #DDEDDC
        static let innerSurface = Color(red: 0xF0 / 255, green: 0xF7 / 255, blue: 0xEF / 255) // #F0F7EF
        static let iconSurface = Color(red: 0x85 / 255, green: 0xC9 / 255, blue: 0x95 / 255)  // #85C995
        static let iconInk = Color(red: 0x25 / 255, green: 0x48 / 255, blue: 0x2B / 255)      // #25482B
        static let primaryText = Color(red: 0x17 / 255, green: 0x1C / 255, blue: 0x17 / 255)  // #171C17
        static let chevron = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)      // #294A2F
        static let border = Color(red: 0xC9 / 255, green: 0xDF / 255, blue: 0xC9 / 255)       // #C9DFC9
    }

    private enum Step: Equatable {
        case student
        case workout
        case day
    }

    private enum DaySelectionPeriod: Int, CaseIterable {
        case currentWeek = 0
        case upcomingWeeks = 1

        var title: LocalizedStringKey {
            switch self {
            case .currentWeek:
                "ui.current_week"
            case .upcomingWeeks:
                "ui.upcoming_weeks"
            }
        }
    }

    private struct AvailableDay: Identifiable {
        let date: Date

        var id: Date { date }
    }

    @Binding var path: [AppRoute]
    let category: TreinoTipo
    let preselectedStudentID: String?
    let startsAtWorkout: Bool
    let preselectedVideo: YoutubeVideo?
    @Environment(\.selectTeacherMainSection) private var selectTeacherMainSection

    @State private var students: [AppUser] = []
    @State private var studentCategories: [String: [TreinoTipo]] = [:]
    @State private var templates: [WorkoutTemplateFS] = []
    @State private var searchText: String = ""
    @State private var studentFilter: TreinoTipo?

    @State private var selectedStudentIDs: Set<String> = []
    @State private var selectedTemplates: [TreinoTipo: WorkoutTemplateFS] = [:]
    @State private var selectedDay: AvailableDay?
    @State private var daySelectionPeriod: DaySelectionPeriod = .currentWeek
    @State private var futureWeekOffset = 0
    @State private var step: Step = .student
    @State private var selectingWorkoutCategory: TreinoTipo?
    @State private var selectedWorkoutSectionKey: String?
    @State private var selectedWorkoutSectionTitle: String?
    @State private var isWorkoutSelectorPresented = false

    @State private var isLoadingInitialData = false
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var successMessage: LocalizedStringKey?

    private let contentMaxWidth: CGFloat = 380

    init(
        path: Binding<[AppRoute]>,
        category: TreinoTipo,
        preselectedStudentID: String? = nil,
        startsAtWorkout: Bool = false,
        preselectedTemplate: WorkoutTemplateFS? = nil,
        preselectedVideo: YoutubeVideo? = nil
    ) {
        self._path = path
        self.category = category
        let studentID = preselectedStudentID?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        self.preselectedStudentID = studentID?.isEmpty == false ? studentID : nil
        self.startsAtWorkout = startsAtWorkout && self.preselectedStudentID != nil
        self.preselectedVideo = preselectedVideo
        _selectedStudentIDs = State(initialValue: self.preselectedStudentID.map { [$0] } ?? [])
        let preselectedTemplateCategory = preselectedTemplate
            .flatMap { TreinoTipo.normalized(from: $0.categoryRaw) }
            ?? category
        _selectedTemplates = State(
            initialValue: preselectedTemplate.map { [preselectedTemplateCategory: $0] } ?? [:]
        )
        _step = State(initialValue: self.startsAtWorkout ? .workout : .student)
    }

    private var filteredStudents: [AppUser] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return students.filter { student in
            let matchesCategory: Bool
            if let studentFilter {
                matchesCategory = student.id.flatMap { studentCategories[$0] }?.contains(studentFilter) == true
            } else {
                matchesCategory = true
            }

            let matchesSearch = query.isEmpty
                || student.name.range(
                    of: query,
                    options: [.caseInsensitive, .diacriticInsensitive]
                ) != nil

            return matchesCategory && matchesSearch
        }
    }

    private var visibleStudentIDs: Set<String> {
        Set(filteredStudents.compactMap {
            let studentId = $0.id?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return studentId.isEmpty ? nil : studentId
        })
    }

    private var areAllVisibleStudentsSelected: Bool {
        !visibleStudentIDs.isEmpty && visibleStudentIDs.isSubset(of: selectedStudentIDs)
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

    private var isVideoFlow: Bool {
        preselectedVideo != nil
    }

    private var selectedVideoTitle: String {
        let title = preselectedVideo?.title.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return title.isEmpty ? AppLocalization.string("workout.youtube_video", locale: locale) : title
    }

    private var selectedVideoURL: String {
        preselectedVideo?.url.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var availableDays: [AvailableDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysUntilSunday = (8 - weekday) % 7

        guard let currentWeekEnd = calendar.date(
            byAdding: .day,
            value: daysUntilSunday,
            to: today
        ) else {
            return []
        }

        switch daySelectionPeriod {
        case .currentWeek:
            return days(startingAt: today, count: daysUntilSunday + 1, calendar: calendar)
        case .upcomingWeeks:
            guard let firstUpcomingWeekStart = calendar.date(
                byAdding: .day,
                value: 1,
                to: currentWeekEnd
            ),
            let weekStart = calendar.date(
                byAdding: .day,
                value: futureWeekOffset * 7,
                to: firstUpcomingWeekStart
            ) else {
                return []
            }
            return days(startingAt: weekStart, count: 7, calendar: calendar)
        }
    }

    private func days(
        startingAt startDate: Date,
        count: Int,
        calendar: Calendar
    ) -> [AvailableDay] {
        (0..<count).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else {
                return nil
            }
            return AvailableDay(date: date)
        }
    }

    private var canAdvanceFromStudent: Bool {
        !selectedStudentIDs.isEmpty
    }

    private var canAdvanceFromWorkout: Bool {
        guard !selectedStudentIDs.isEmpty else { return false }
        return isVideoFlow || !selectedTemplates.isEmpty
    }

    private var canSend: Bool {
        selectedDay != nil
            && !selectedStudentIDs.isEmpty
            && (isVideoFlow || !selectedTemplates.isEmpty)
            && !isSending
    }

    var body: some View {
        ZStack {
            AppThemeBackgroundImage()

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                stepScrollableContent
                fixedStepAction

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
        .blur(radius: isWorkoutSelectorPresented ? 8 : 0)
        .animation(.easeInOut(duration: 0.20), value: isWorkoutSelectorPresented)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { goBack() } label: {
                    ZStack {
                        Color.clear.frame(width: 44, height: 44)
                        Image(systemName: "chevron.left")
                            .foregroundStyle(Theme.Colors.systemAccentForeground())
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                if step != .day {
                    Text("ui.send_workout")
                        .font(Theme.Fonts.headerTitle())
                        .foregroundStyle(Theme.Colors.ink())
                        .lineLimit(1)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appThemeNavigationBarColorScheme()
        .task { await bootstrap() }
        .sheet(isPresented: $isWorkoutSelectorPresented, onDismiss: closeWorkoutSelector) {
            if let selectingWorkoutCategory {
                WorkoutTemplateSelectionSheet(
                    category: selectingWorkoutCategory,
                    sectionOptions: sectionOptions(for: selectingWorkoutCategory),
                    templates: templates,
                    selectedSectionKey: $selectedWorkoutSectionKey,
                    selectedSectionTitle: $selectedWorkoutSectionTitle,
                    selectedTemplateID: selectedTemplates[selectingWorkoutCategory]?.id,
                    isLoading: isLoadingInitialData,
                    onSelectTemplate: selectTemplate
                )
                .presentationDetents([.fraction(0.80)])
            }
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            stepItem(
                number: 1,
                title: .localized("common.student"),
                isActive: step == .student,
                isComplete: step != .student
            )
            Rectangle().fill(Theme.Colors.divider).frame(height: 1)
            stepItem(
                number: 2,
                title: .localized(isVideoFlow ? "common.video" : "ui.workout"),
                isActive: step == .workout,
                isComplete: step == .day
            )
            Rectangle().fill(Theme.Colors.divider).frame(height: 1)
            stepItem(
                number: 3,
                title: .localized("ui.day"),
                isActive: step == .day,
                isComplete: false
            )
        }
    }

    private func stepItem(
        number: Int,
        title: DisplayText,
        isActive: Bool,
        isComplete: Bool
    ) -> some View {
        VStack(spacing: 4) {
            ZStack {
                // Tema Claro: etapa ativa/concluída em verde militar translúcido com número branco; pendente mantém o estilo discreto original
                Circle()
                    .fill(
                        appTheme == .light && (isActive || isComplete)
                            ? AnyShapeStyle(AppThemePalette.lightBar.opacity(0.80))
                            : AnyShapeStyle(AppThemeAdaptiveColor((isActive || isComplete) ? Color.green.opacity(0.18) : Color.white.opacity(0.10)))
                    )
                    .frame(width: 26, height: 26)
                Text("\(number)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(
                        appTheme == .light && (isActive || isComplete)
                            ? AnyShapeStyle(Color.white)
                            : AnyShapeStyle(AppThemeAdaptiveColor((isActive || isComplete) ? .green : .white.opacity(0.55)))
                    )
            }
            title.view()
                .font(.system(size: 11, weight: .medium))
            .foregroundStyle(AppThemeAdaptiveColor((isActive || isComplete) ? .white.opacity(0.92) : .white.opacity(0.55)))
        }
    }

    private var studentStepLayout: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 14) {
                    stepIndicator
                    studentSection
                }
                .frame(maxWidth: contentMaxWidth)
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer(minLength: 0)
            }

            ScrollView(showsIndicators: false) {
                HStack {
                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: 14) {
                        studentListContent

                        if let errorMessage {
                            TeacherWorkoutTemplatesMessageCard(text: errorMessage, isError: true)
                        }
                    }
                    .frame(maxWidth: contentMaxWidth)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                    Spacer(minLength: 0)
                }
            }
        }
    }

    @ViewBuilder
    private var stepScrollableContent: some View {
        switch step {
        case .student:
            studentStepLayout
        case .workout, .day:
            nonStudentStepLayout
        }
    }

    private var nonStudentStepLayout: some View {
        ScrollView(showsIndicators: false) {
            HStack {
                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 14) {
                    stepIndicator

                    if step == .workout {
                        selectedStudentsSummary
                        if isVideoFlow {
                            selectedVideoSummary
                        } else {
                            templateSection
                        }
                    } else {
                        if isVideoFlow {
                            selectedVideoSummary
                        } else {
                            selectedWorkoutsSummary
                        }
                        daySection
                    }

                    if let errorMessage {
                        TeacherWorkoutTemplatesMessageCard(text: errorMessage, isError: true)
                    }

                    if let successMessage {
                        localizedMessageCard(text: successMessage, isError: false)
                    }
                }
                .frame(maxWidth: contentMaxWidth)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)

                Spacer(minLength: 0)
            }
        }
    }

    private var fixedStepAction: some View {
        HStack {
            Spacer(minLength: 0)

            stepAction
                .frame(maxWidth: contentMaxWidth)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var stepAction: some View {
        switch step {
        case .student:
            nextButton(enabled: canAdvanceFromStudent) {
                step = .workout
            }
        case .workout:
            nextButton(enabled: canAdvanceFromWorkout) {
                Task { await advanceToDaySelection() }
            }
        case .day:
            sendButton
        }
    }

    private var studentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            studentSearchField
            studentFilterRow
            selectAllVisibleStudentsButton
        }
    }

    private var studentFilterRow: some View {
        HStack(spacing: 6) {
            studentFilterChip(title: "common.all", isSelected: studentFilter == nil) {
                studentFilter = nil
            }
            studentFilterChip(title: "video.category.crossfit", isSelected: studentFilter == .crossfit) {
                studentFilter = .crossfit
            }
            studentFilterChip(title: "video.category.gym", isSelected: studentFilter == .academia) {
                studentFilter = .academia
            }
            studentFilterChip(title: "video.category.home", isSelected: studentFilter == .emCasa) {
                studentFilter = .emCasa
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func studentFilterChip(
        title: LocalizedStringKey,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            // Tema Claro: selecionado em verde militar translúcido (padrão do botão Sair); não selecionado em verde pastel
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(
                    appTheme == .light
                        ? AnyShapeStyle(isSelected ? Color.white : LightColors.primaryText)
                        : AnyShapeStyle(Theme.Colors.ink(0.92))
                )
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 6)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity)
                .background(
                    appTheme == .light
                        ? AnyShapeStyle(isSelected ? AppThemePalette.lightBar.opacity(0.80) : LightColors.cardSurface)
                        : isSelected
                            ? AnyShapeStyle(Theme.Colors.primaryGreen.opacity(0.18))
                            : AnyShapeStyle(Theme.Colors.glass(0.68))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            appTheme == .light
                                ? (isSelected ? AppThemePalette.lightBar.opacity(0.90) : LightColors.border)
                                : isSelected
                                    ? Theme.Colors.primaryGreen.opacity(0.30)
                                    : Theme.Colors.primaryGreen.opacity(0.28),
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var selectAllVisibleStudentsButton: some View {
        Button(action: toggleAllVisibleStudents) {
            HStack(spacing: 10) {
                Spacer()

                if areAllVisibleStudentsSelected {
                    Text("ui.deselect_all")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.systemAccentForeground())
                } else {
                    Text("ui.select_all")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.ink(0.75))
                }

                Image(systemName: areAllVisibleStudentsSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(AppThemeColor(dark: areAllVisibleStudentsSelected ? .green : .white.opacity(0.55), light: LightColors.iconInk))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .buttonStyle(.plain)
        .disabled(visibleStudentIDs.isEmpty || isSending)
        .opacity(visibleStudentIDs.isEmpty ? 0.45 : 1)
    }

    private var studentSearchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.Colors.ink(0.55))
            TextField("ui.search_student", text: $searchText)
                .foregroundStyle(Theme.Colors.ink(0.92))
                .tint(.green)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Theme.Colors.glass(0.68))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.Colors.cardBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var studentListContent: some View {
        if isLoadingInitialData {
            loadingRow("ui.loading_students")
        } else if filteredStudents.isEmpty {
            emptyRow(
                searchText.isEmpty
                    ? .localized("ui.no_linked_student_period")
                    : .localized("ui.no_student_found_period")
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < filteredStudents.count - 1 {
                    Divider()
                        .background(Theme.Colors.divider)
                        .padding(.leading, 54)
                }
            }
        }
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
        .disabled(isSending)
    }

    private func studentRow(_ student: AppUser) -> some View {
        let selected = isSelected(student)
        let selectionIcon = selected ? "checkmark.circle.fill" : "circle"
        let selectionColor: Color = selected ? .green : .white.opacity(0.35)

        return HStack(spacing: 14) {
            UserAvatarView(base64: student.photoBase64, size: 28)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(student.name)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                Text(
                    String(
                        format: AppLocalization.string("ui.category_value", locale: locale),
                        locale: locale,
                        arguments: [studentCategoryText(student)]
                    )
                )
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.ink(0.55))
            }

            Spacer()

            Image(systemName: selectionIcon)
                .font(.system(size: 20))
                .foregroundStyle(AppThemeColor(dark: selectionColor, light: LightColors.iconInk))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var selectedStudentsSummary: some View {
        VStack(spacing: 0) {
            cardSectionTitle("ui.selected_students")

            VStack(alignment: .leading, spacing: 8) {
                ForEach(selectedStudents) { student in
                    Text(student.name)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.ink(0.55))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
        .disabled(isSending)
    }

    private var templateSection: some View {
        VStack(spacing: 0) {
            templateSectionTitle

            Rectangle()
                .fill(Theme.Colors.ink(0.08))
                .frame(height: 1)

            templatePicker(category: .crossfit, title: "video.category.crossfit")
            templatePickerDivider
            templatePicker(category: .academia, title: "video.category.gym")
            templatePickerDivider
            templatePicker(category: .emCasa, title: "ui.home_workouts")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }

    private var templateSectionTitle: some View {
        Text("ui.select_workout")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Theme.Colors.ink(0.55))
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func templatePicker(category: TreinoTipo, title: LocalizedStringKey) -> some View {
        let selection = selectedTemplates[category]

        return VStack(alignment: .leading, spacing: 6) {
            categoryHeader(category: category, title: title)
            templatePickerContent(
                category: category,
                selection: selection
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var templatePickerDivider: some View {
        Rectangle()
            .fill(Theme.Colors.ink(0.08))
            .frame(height: 1)
            .padding(.leading, 14)
            .padding(.vertical, 4)
    }

    private func categoryHeader(category: TreinoTipo, title: LocalizedStringKey) -> some View {
        HStack(spacing: 8) {
            Image(systemName: categoryIcon(for: category))
                .font(.system(size: 14))
                .foregroundStyle(AppThemeColor(dark: Theme.Colors.systemAccentForeground(0.85).dark, light: LightColors.iconInk))

            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.ink(0.55))
        }
    }

    @ViewBuilder
    private func templatePickerContent(
        category: TreinoTipo,
        selection: WorkoutTemplateFS?
    ) -> some View {
        if isLoadingInitialData {
            templatePickerLabel(
                title: .localized("ui.loading_workouts"),
                isSelected: false
            )
        } else {
            Button {
                openWorkoutSelector(for: category)
            } label: {
                templatePickerLabel(
                    title: selection.map { .verbatim($0.title) } ?? .localized("ui.select_workout_2"),
                    isSelected: selection != nil
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func templatePickerLabel(
        title: DisplayText,
        isSelected: Bool
    ) -> some View {
        // Tema Claro: selecionado em verde militar translúcido (padrão do botão Sair) com texto/seta brancos;
        // sem treino escolhido (ou carregando) em cinza claro (mesmos tons do botão Próximo desabilitado).
        let isLightSelected = appTheme == .light && isSelected
        let isLightUnselected = appTheme == .light && !isSelected

        return HStack {
            title.view()
                .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(isLightSelected ? AnyShapeStyle(Color.white) : AnyShapeStyle(Theme.Colors.ink(0.92)))
            .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.down")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(
                    isLightSelected
                        ? AnyShapeStyle(Color.white)
                        : isLightUnselected
                            ? AnyShapeStyle(Theme.Colors.ink(0.70))
                            : AnyShapeStyle(AppThemeColor(dark: isSelected ? Theme.Colors.primaryGreen.opacity(0.85) : .white.opacity(0.25), light: LightColors.iconInk))
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            isLightSelected
                ? AnyShapeStyle(AppThemePalette.lightBar.opacity(0.80))
                : isLightUnselected
                    ? AnyShapeStyle(Theme.Colors.ink(0.10))
                    : AnyShapeStyle(AppThemeAdaptiveColor(isSelected ? Theme.Colors.primaryGreen.opacity(0.14) : Color.black.opacity(0.68)))
        )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isLightSelected
                        ? AnyShapeStyle(AppThemePalette.lightBar.opacity(0.90))
                        : isLightUnselected
                            ? AnyShapeStyle(Theme.Colors.ink(0.12))
                            : AnyShapeStyle(isSelected ? Theme.Colors.primaryGreen.opacity(0.35) : Theme.Colors.primaryGreen.opacity(0.28)),
                    lineWidth: 1
                )
        )
    }

    private func sectionOptions(for category: TreinoTipo) -> [WorkoutSectionOption] {
        switch category {
        case .crossfit:
            return [
                .init(title: AppLocalization.string("library.crossfit.girls_wods", locale: locale), sectionKey: "girlsWods"),
                .init(title: AppLocalization.string("library.crossfit.hero_tribute_workouts", locale: locale), sectionKey: "heroTributeWorkouts"),
                .init(title: AppLocalization.string("library.crossfit.open_wods", locale: locale), sectionKey: "openWods"),
                .init(title: AppLocalization.string("library.crossfit.named_wods", locale: locale), sectionKey: "wodsNomeados"),
                .init(title: AppLocalization.string("library.crossfit.qualifier_competition_wods", locale: locale), sectionKey: "qualifiersCompeticoes"),
                .init(title: AppLocalization.string("ui.my_workouts", locale: locale), sectionKey: "meusTreinos")
            ]
        case .academia, .emCasa:
            return [
                .init(title: AppLocalization.string("ui.chest", locale: locale), sectionKey: "peito"),
                .init(title: AppLocalization.string("ui.back", locale: locale), sectionKey: "costas"),
                .init(title: AppLocalization.string("ui.legs", locale: locale), sectionKey: "pernas"),
                .init(title: AppLocalization.string("ui.shoulders", locale: locale), sectionKey: "ombros"),
                .init(title: AppLocalization.string("ui.arms", locale: locale), sectionKey: "bracos"),
                .init(title: AppLocalization.string("ui.core_abs", locale: locale), sectionKey: "core"),
                .init(title: AppLocalization.string("ui.full_body", locale: locale), sectionKey: "fullBody"),
                .init(title: AppLocalization.string("ui.my_workouts", locale: locale), sectionKey: "meusTreinos")
            ]
        }
    }

    private func openWorkoutSelector(for category: TreinoTipo) {
        selectingWorkoutCategory = category
        selectedWorkoutSectionKey = selectedTemplates[category]?.sectionKey
        selectedWorkoutSectionTitle = sectionOptions(for: category)
            .first { $0.sectionKey == selectedWorkoutSectionKey }?
            .title
        isWorkoutSelectorPresented = true
    }

    private func selectTemplate(_ template: WorkoutTemplateFS) {
        guard let selectingWorkoutCategory else { return }
        selectedTemplates[selectingWorkoutCategory] = template
        clearMessages()
        closeWorkoutSelector()
    }

    private func closeWorkoutSelector() {
        isWorkoutSelectorPresented = false
        selectingWorkoutCategory = nil
        selectedWorkoutSectionKey = nil
        selectedWorkoutSectionTitle = nil
    }

    private var selectedWorkoutsSummary: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(selectedTemplatesInOrder, id: \.category) { item in
                    selectedWorkoutRow(category: item.category, template: item.template)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }

    private var selectedVideoSummary: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(AppThemeColor(dark: Theme.Colors.systemAccentForeground(0.85).dark, light: LightColors.iconInk))

                    Text("ui.selected_video")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.Colors.ink(0.55))
                }

                Text(selectedVideoTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))

                if !selectedVideoURL.isEmpty {
                    Text(selectedVideoURL)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.ink(0.55))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppThemeColor(dark: Color.black.opacity(0.65), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Color.white.opacity(0.08), light: LightColors.border), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }

    private func selectedWorkoutRow(
        category: TreinoTipo,
        template: WorkoutTemplateFS
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Image(systemName: categoryIcon(for: category))
                    .font(.system(size: 13))
                    .foregroundStyle(AppThemeColor(dark: Theme.Colors.systemAccentForeground(0.85).dark, light: LightColors.iconInk))

                Text(category.localizedDisplayName(locale: locale))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.ink(0.55))
            }

            Text(template.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
        }
    }

    private var daySection: some View {
        VStack(spacing: 0) {
            daySelectionPeriodRow
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, daySelectionPeriod == .upcomingWeeks ? 12 : 16)
            .disabled(isSending)
            .onChange(of: daySelectionPeriod) { _ in
                selectedDay = nil
                futureWeekOffset = 0
            }

            if daySelectionPeriod == .upcomingWeeks {
                futureWeekNavigation
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }

            VStack(spacing: 0) {
                ForEach(Array(availableDays.enumerated()), id: \.element.id) { index, day in
                    Button {
                        selectedDay = day
                        clearMessages()
                    } label: {
                        dayRow(day: day, isSelected: selectedDay?.id == day.id)
                    }
                    .buttonStyle(.plain)

                    if index < availableDays.count - 1 {
                        Divider()
                            .background(Theme.Colors.divider)
                            .padding(.leading, 48)
                    }
                }
            }
            .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.innerSurface))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1)
            )
            .disabled(isSending)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }

    private var daySelectionPeriodRow: some View {
        HStack(spacing: 6) {
            ForEach(DaySelectionPeriod.allCases, id: \.rawValue) { (period: DaySelectionPeriod) in
                let isSelected: Bool = daySelectionPeriod == period
                // Tema Claro: selecionado em verde militar translúcido (padrão do botão Sair); não selecionado em verde pastel
                let isLight: Bool = appTheme == .light
                let backgroundColor: AnyShapeStyle = isLight
                    ? AnyShapeStyle(isSelected ? AppThemePalette.lightBar.opacity(0.80) : LightColors.cardSurface)
                    : isSelected
                        ? AnyShapeStyle(Theme.Colors.primaryGreen.opacity(0.18))
                        : AnyShapeStyle(Theme.Colors.glass(0.68))
                let borderColor: Color = isLight
                    ? (isSelected ? AppThemePalette.lightBar.opacity(0.90) : LightColors.border)
                    : isSelected
                        ? Theme.Colors.primaryGreen.opacity(0.30)
                        : Theme.Colors.primaryGreen.opacity(0.28)
                let textStyle: AnyShapeStyle = isLight
                    ? AnyShapeStyle(isSelected ? Color.white : LightColors.primaryText)
                    : AnyShapeStyle(Theme.Colors.ink(0.92))

                Button {
                    daySelectionPeriod = period
                } label: {
                    Text(period.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(textStyle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity)
                        .background(backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderColor, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var futureWeekNavigation: some View {
        HStack {
            Button {
                futureWeekOffset -= 1
                selectedDay = nil
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        futureWeekOffset == 0
                            ? AnyShapeStyle(AppThemeAdaptiveColor(.white.opacity(0.25)))
                            : AnyShapeStyle(AppThemeColor(dark: Theme.Colors.primaryGreen, light: LightColors.iconInk))
                    )
                    .frame(width: 32, height: 28)
            }
            .buttonStyle(.plain)
            .disabled(futureWeekOffset == 0 || isSending)

            Spacer()

            if let firstDay = availableDays.first?.date,
               let lastDay = availableDays.last?.date {
                Text(
                    String(
                        format: AppLocalization.string("common.date_range", locale: locale),
                        locale: locale,
                        arguments: [dateTitle(for: firstDay), dateTitle(for: lastDay)]
                    )
                )
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.ink(0.55))
            }

            Spacer()

            Button {
                futureWeekOffset += 1
                selectedDay = nil
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppThemeColor(dark: Theme.Colors.accentForeground.dark, light: LightColors.iconInk))
                    .frame(width: 32, height: 28)
            }
            .buttonStyle(.plain)
            .disabled(isSending)
        }
    }

    private func dayRow(day: AvailableDay, isSelected: Bool) -> some View {
        let selectionIcon = isSelected ? "checkmark.circle.fill" : "circle"
        let selectionColor: Color = isSelected ? .green : .white.opacity(0.35)

        return HStack(spacing: 12) {
            Image(systemName: selectionIcon)
                .font(.system(size: 20))
                .foregroundStyle(AppThemeColor(dark: selectionColor, light: LightColors.iconInk))
            Text(weekdayTitle(for: day.date))
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
            Spacer()
            Text(dateTitle(for: day.date))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.Colors.ink(0.55))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(isSelected ? Theme.Colors.primaryGreen.opacity(0.14) : Color.clear)
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
            Text("ui.next")
            Spacer()
        }
        .modifier(LightMilitaryActionButtonModifier())
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }

    private var sendButtonContent: some View {
        HStack {
            Spacer()
            if isSending {
                ProgressView().tint(Theme.Colors.ink())
            } else {
                Text("ui.send_workout")
            }
            Spacer()
        }
        .modifier(LightMilitaryActionButtonModifier())
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Theme.Colors.ink(0.92))
    }

    private func cardSectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Theme.Colors.ink(0.35))
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 18)
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

    private func loadingRow(_ title: LocalizedStringKey) -> some View {
        HStack(spacing: 10) {
            ProgressView()
            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.ink(0.55))
        }
        .padding(.vertical, 10)
    }

    private func emptyRow(
        _ title: DisplayText
    ) -> some View {
        title.view()
        .font(.system(size: 14))
        .foregroundStyle(Theme.Colors.ink(0.55))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
    }

    private func studentCategoryText(_ student: AppUser) -> String {
        guard let studentId = student.id else { return "" }
        return (studentCategories[studentId] ?? [])
            .map { $0.localizedDisplayName(locale: locale) }
            .joined(separator: " / ")
    }

    private func templateMenuTitle(_ template: WorkoutTemplateFS) -> String {
        "\(template.title) • \(template.sectionKey)"
    }

    private func weekdayTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("EEEE")
        return formatter.string(from: date).capitalized(with: formatter.locale)
    }

    private func dateTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("ddMM")
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

    private func toggleAllVisibleStudents() {
        guard !visibleStudentIDs.isEmpty else { return }

        if areAllVisibleStudentsSelected {
            selectedStudentIDs.subtract(visibleStudentIDs)
        } else {
            selectedStudentIDs.formUnion(visibleStudentIDs)
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
            errorMessage = AppLocalization.string("ui.unable_to_identify_the_signed_in_trainer", locale: locale)
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
                $0.sorted {
                    $0.localizedDisplayName(locale: locale)
                        .localizedCaseInsensitiveCompare($1.localizedDisplayName(locale: locale)) == .orderedAscending
                }
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
                errorMessage = AppLocalization.string("ui.unable_to_identify_the_signed_in_trainer", locale: locale)
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

                if let video = preselectedVideo {
                    let titleTrim = video.title.trimmingCharacters(in: .whitespacesAndNewlines)
                    let safeTitle = titleTrim.isEmpty ? "Vídeo do YouTube" : titleTrim
                    let urlTrim = video.url.trimmingCharacters(in: .whitespacesAndNewlines)
                    let blocks: [BlockFS] = [
                        BlockFS(
                            id: UUID().uuidString,
                            name: "Vídeo",
                            details: urlTrim.isEmpty ? "-" : urlTrim
                        )
                    ]

                    _ = try await FirestoreRepository.shared.upsertDay(
                        weekId: week.weekId,
                        dayId: nil,
                        dayIndex: dayIndex,
                        dayName: dayName,
                        date: selectedDate,
                        title: safeTitle,
                        description: urlTrim.isEmpty ? "-" : urlTrim,
                        blocks: blocks
                    )
                } else {
                    for (templateCategory, template) in selectedTemplatesInOrder {
                        let blocks = template.blocks ?? []
                        _ = try await FirestoreRepository.shared.upsertDay(
                            weekId: week.weekId,
                            dayId: nil,
                            dayIndex: dayIndex,
                            dayName: dayName,
                            date: selectedDate,
                            title: template.title,
                            description: template.description,
                            blocks: blocks,
                            categoryRaw: templateCategory.rawValue
                        )
                    }
                }
            }
            successMessage = isVideoFlow
                ? "ui.video_sent_successfully"
                : "ui.workout_sent_successfully"
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            path.removeAll()
            if isVideoFlow {
                selectTeacherMainSection(.workouts)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    private func localizedMessageCard(
        text: LocalizedStringKey,
        isError: Bool
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .yellow.opacity(0.85) : .green.opacity(0.85))

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Theme.Colors.ink(0.75))

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppThemeColor(dark: Color.black.opacity(0.35), light: LightColors.cardSurface))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.Colors.ink(0.10), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
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

private struct WorkoutTemplateSelectionSheet: View {

    let category: TreinoTipo
    let sectionOptions: [WorkoutSectionOption]
    let templates: [WorkoutTemplateFS]
    @Binding var selectedSectionKey: String?
    @Binding var selectedSectionTitle: String?
    let selectedTemplateID: String?
    let isLoading: Bool
    let onSelectTemplate: (WorkoutTemplateFS) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.appTheme) private var appTheme
    @State private var expandedPicker: ExpandedPicker?
    @State private var pendingSelectedTemplate: WorkoutTemplateFS?
    @State private var loadedSectionTemplates: [WorkoutTemplateFS] = []
    @State private var isLoadingSectionTemplates = false
    @State private var hasLoadedSectionTemplates = false
    @State private var sectionTemplatesLoadID = UUID()

    private enum ExpandedPicker: Equatable {
        case section
        case template
    }

    private var sectionTemplates: [WorkoutTemplateFS] {
        loadedSectionTemplates
    }

    private var selectedTemplate: WorkoutTemplateFS? {
        pendingSelectedTemplate
    }

    private var templatePickerTitle: String {
        selectedTemplate?.title ?? ""
    }

    private var templatePickerLocalizedTitle: LocalizedStringKey? {
        guard selectedTemplate == nil else { return nil }
        guard selectedSectionKey != nil else {
            return "ui.select_a_section_first"
        }
        if isLoading || isLoadingSectionTemplates || !hasLoadedSectionTemplates {
            return "ui.loading_workouts"
        }
        return "ui.select_workout_2"
    }

    private var canConfirmSelection: Bool {
        selectedSectionKey != nil && pendingSelectedTemplate != nil
    }

    var body: some View {
        ZStack {
            Theme.Colors.sheetBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(Theme.Colors.ink(0.18))
                    .frame(width: 44, height: 5)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)

                Text(
                    String(
                        format: AppLocalization.string("ui.select_workout_value", locale: locale),
                        locale: locale,
                        arguments: [category.localizedDisplayName(locale: locale)]
                    )
                )
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.Colors.ink())
                    .lineLimit(1)
                    .padding(.top, 4)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        selectionField(title: "ui.section") {
                            sectionPickerField
                        }

                        if expandedPicker == .section {
                            sectionOptionsList
                        }

                        selectionField(title: "ui.workout") {
                            templatePickerField
                        }

                        if expandedPicker == .template {
                            templateOptionsList
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                }

                bottomActions
            }
        }
        .appThemeNavigationBarColorScheme()
        .onAppear {
            pendingSelectedTemplate = templates.first { $0.id == selectedTemplateID }
            if let selectedSectionKey {
                let selectedSectionTitle = selectedSectionTitle
                    ?? sectionOptions.first { $0.sectionKey == selectedSectionKey }?.title
                    ?? selectedSectionKey
                Task {
                    await loadSectionTemplates(
                        sectionKey: selectedSectionKey,
                        sectionTitle: selectedSectionTitle
                    )
                }
            }
        }
    }

    private func selectionField<Content: View>(
        title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Theme.Colors.ink(0.75))
            content()
        }
    }

    private var sectionPickerField: some View {
        Button {
            togglePicker(.section)
        } label: {
            WorkoutPickerLabel(
                title: selectedSectionTitle.map(DisplayText.verbatim) ?? .localized("ui.select_section"),
                isSelected: selectedSectionKey != nil
            )
        }
        .buttonStyle(.plain)
    }

    private var templatePickerField: some View {
        let isEnabled = selectedSectionKey != nil
            && !isLoading
            && !isLoadingSectionTemplates
            && hasLoadedSectionTemplates

        return Button {
            togglePicker(.template)
        } label: {
            WorkoutPickerLabel(
                title: templatePickerLocalizedTitle.map(DisplayText.localized)
                    ?? .verbatim(templatePickerTitle),
                isSelected: selectedTemplate != nil
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }

    private var sectionOptionsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(sectionOptions.enumerated()), id: \.element.id) { index, option in
                Button {
                    selectSection(option)
                } label: {
                    selectionRow(
                        title: option.title,
                        isSelected: option.sectionKey == selectedSectionKey
                    )
                }
                .buttonStyle(.plain)

                if index < sectionOptions.count - 1 {
                    selectionDivider
                }
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.glass(0.68))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.Colors.cardBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var templateOptionsList: some View {
        if isLoading || isLoadingSectionTemplates || !hasLoadedSectionTemplates {
            HStack(spacing: 10) {
                ProgressView()
                Text("ui.loading_workouts")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.ink(0.55))
            }
            .padding(.vertical, 14)
        } else if sectionTemplates.isEmpty {
            Text("ui.no_workout_registered_2")
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.ink(0.55))
                .padding(.vertical, 14)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(sectionTemplates.enumerated()), id: \.element.id) { index, template in
                    Button {
                        pendingSelectedTemplate = template
                        expandedPicker = nil
                    } label: {
                        selectionRow(
                            title: template.title,
                            isSelected: template.id == pendingSelectedTemplate?.id
                        )
                    }
                    .buttonStyle(.plain)

                    if index < sectionTemplates.count - 1 {
                        selectionDivider
                    }
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Theme.Colors.glass(0.68))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.Colors.cardBorder, lineWidth: 1)
            )
        }
    }

    private func togglePicker(_ picker: ExpandedPicker) {
        expandedPicker = expandedPicker == picker ? nil : picker
    }

    private func selectSection(_ option: WorkoutSectionOption) {
        if selectedSectionKey != option.sectionKey {
            pendingSelectedTemplate = nil
        }
        selectedSectionKey = option.sectionKey
        selectedSectionTitle = option.title
        expandedPicker = nil
        Task {
            await loadSectionTemplates(
                sectionKey: option.sectionKey,
                sectionTitle: option.title
            )
        }
    }

    private func loadSectionTemplates(sectionKey: String, sectionTitle: String) async {
        let loadID = UUID()
        sectionTemplatesLoadID = loadID
        isLoadingSectionTemplates = true
        hasLoadedSectionTemplates = false
        loadedSectionTemplates = []

        let teacherId = (Auth.auth().currentUser?.uid ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            guard sectionTemplatesLoadID == loadID,
                  selectedSectionKey == sectionKey else { return }
            isLoadingSectionTemplates = false
            return
        }

        do {
            var fetched = try await FirestoreRepository.shared.getWorkoutTemplates(
                teacherId: teacherId,
                categoryRaw: category.rawValue,
                sectionKey: sectionKey
            )

            if sectionKey != "meusTreinos" {
                let didInsert = try await WorkoutTemplateDefaultsSeeder.shared.seedMissingDefaultsIfNeeded(
                    teacherId: teacherId,
                    category: category,
                    sectionKey: sectionKey,
                    sectionTitle: sectionTitle,
                    existingTemplates: fetched
                )

                if didInsert {
                    fetched = try await FirestoreRepository.shared.getWorkoutTemplates(
                        teacherId: teacherId,
                        categoryRaw: category.rawValue,
                        sectionKey: sectionKey
                    )
                }
            }

            guard sectionTemplatesLoadID == loadID,
                  selectedSectionKey == sectionKey else { return }
            loadedSectionTemplates = fetched
            if let pendingSelectedTemplate,
               !fetched.contains(where: { $0.id == pendingSelectedTemplate.id }) {
                self.pendingSelectedTemplate = nil
            }
            hasLoadedSectionTemplates = true
            isLoadingSectionTemplates = false
        } catch {
            guard sectionTemplatesLoadID == loadID,
                  selectedSectionKey == sectionKey else { return }
            isLoadingSectionTemplates = false
        }
    }

    private func selectionRow(title: String, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink(0.92))

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(Theme.Colors.icon(isSelected ? Theme.Colors.primaryGreen : .white.opacity(0.25)))
                .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private var selectionDivider: some View {
        Rectangle()
            .fill(Theme.Colors.ink(0.08))
            .frame(height: 1)
            .padding(.leading, 14)
    }

    private var bottomActions: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Text("common.cancel")
                    .font(.system(size: 15, weight: .bold))
                    // Tema Claro: cores do botão Sair da ProfileView (medidas originais). Tema Escuro: valores originais.
                    .foregroundStyle(appTheme == .light ? AnyShapeStyle(Color.white) : AnyShapeStyle(Theme.Colors.ink(0.85)))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        appTheme == .light
                            ? AnyShapeStyle(AppThemePalette.lightBar.opacity(0.80))
                            : AnyShapeStyle(Theme.Colors.glass(0.68))
                    )
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                appTheme == .light
                                    ? AnyShapeStyle(AppThemePalette.lightBar.opacity(0.90))
                                    : AnyShapeStyle(Theme.Colors.cardBorder),
                                lineWidth: 1
                            )
                    )
            }
            .buttonStyle(.plain)

            Button {
                guard let pendingSelectedTemplate else { return }
                onSelectTemplate(pendingSelectedTemplate)
                dismiss()
            } label: {
                Text("ui.select")
                    .frame(maxWidth: .infinity)
                    // Tema Claro (habilitado): cores do botão Sair. Desabilitado/Tema Escuro: `primaryGreenActionButton()` original.
                    .modifier(LightMilitaryActionButtonModifier())
            }
            .buttonStyle(.plain)
            .disabled(!canConfirmSelection)
            .opacity(canConfirmSelection ? 1 : 0.45)
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 16)
    }
}
