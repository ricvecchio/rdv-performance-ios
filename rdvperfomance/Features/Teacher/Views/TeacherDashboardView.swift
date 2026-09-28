import SwiftUI

enum TeacherQuickAccessItem: String, CaseIterable, Codable, Hashable, Identifiable {
    case sendWorkout = "sendWorkout"
    case createWorkout = "createWorkout"
    case workoutLibrary = "workoutLibrary"
    case importWorkout = "importWorkout"
    case personalRecords = "personalRecords"
    case myVideos = "myVideos"

    var id: String { rawValue }

    static let defaultItems: [TeacherQuickAccessItem] = [
        .workoutLibrary,
        .importWorkout,
        .myVideos
    ]

    var title: String {
        switch self {
        case .sendWorkout: "Enviar treino"
        case .createWorkout: "Criar treino"
        case .workoutLibrary: "Biblioteca de Treinos"
        case .importWorkout: "Importar"
        case .personalRecords: "Meus Recordes"
        case .myVideos: "Meus Vídeos"
        }
    }

    var subtitle: String {
        switch self {
        case .sendWorkout: "Envie um treino para seus alunos"
        case .createWorkout: "Monte um novo treino"
        case .workoutLibrary: "Use modelos prontos"
        case .importWorkout: "De competições ou bibliotecas"
        case .personalRecords: "Acompanhe e registre seus resultados"
        case .myVideos: "Organize seus vídeos de movimentos"
        }
    }

    var systemImage: String {
        switch self {
        case .sendWorkout: "paperplane.fill"
        case .createWorkout: "plus.circle.fill"
        case .workoutLibrary: "square.grid.2x2.fill"
        case .importWorkout: "tablecells.fill"
        case .personalRecords: "trophy.fill"
        case .myVideos: "video.fill"
        }
    }
}

struct TeacherDashboardView: View {

    private struct TodaySummary {
        let studentsWithWorkout: Int
        let completedStudents: Int
        let studentsWithoutWorkout: Int
    }

    @Binding var path: [AppRoute]
    let category: TreinoTipo
    @Environment(\.selectTeacherMainSection) private var selectTeacherMainSection
    @EnvironmentObject private var session: AppSession

    @State private var todaySummary: TodaySummary?
    @State private var isLoadingSummary = true
    @State private var isSummaryLoadInProgress = false
    @State private var quickAccessItems = TeacherQuickAccessItem.defaultItems
    @State private var editableQuickAccessItems = TeacherQuickAccessItem.defaultItems
    @State private var isQuickAccessEditorPresented = false
    @State private var isSavingQuickAccessItems = false
    @State private var isLoadingQuickAccessItems = false
    @State private var quickAccessEditorError: String?

    private let contentMaxWidth: CGFloat = 380
    private let summaryColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

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

                            summaryCard

                            quickAccessCard

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
                        isHomeSelected: true,
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

            ToolbarItem(placement: .principal) {
                Text("Área do Professor")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            Task { await loadTodaySummary() }
            Task { await loadQuickAccessItems() }
        }
        .sheet(isPresented: $isQuickAccessEditorPresented) {
            quickAccessEditorSheet
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)

            Text("Acompanhando a evolução da sua turma.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Resumo de hoje")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white.opacity(0.92))

                Spacer()

                Text(todayText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))
            }

            LazyVGrid(columns: summaryColumns, spacing: 8) {
                summaryItem(
                    value: todaySummary?.studentsWithWorkout,
                    title: "Treinos hoje",
                    icon: "person.3.fill"
                )
                summaryItem(
                    value: todaySummary?.completedStudents,
                    title: "Concluídos",
                    icon: "checkmark.circle.fill"
                )
                summaryItem(
                    value: todaySummary?.studentsWithoutWorkout,
                    title: "Sem treino",
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .red.opacity(0.9)
                )
            }
        }
        .padding(14)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var quickAccessCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Acesso rápido")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white.opacity(0.92))

                Spacer()

                Button {
                    editableQuickAccessItems = quickAccessItems
                    quickAccessEditorError = nil
                    isQuickAccessEditorPresented = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.55))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Personalizar Acesso rápido")
                .disabled(isLoadingQuickAccessItems)
            }

            VStack(spacing: 12) {
                ForEach(quickAccessItems) { item in
                    quickAccessItem(
                        title: item.title,
                        subtitle: item.subtitle,
                        icon: item.systemImage
                    ) {
                        openQuickAccessItem(item)
                    }
                }
            }
        }
        .padding(14)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var quickAccessEditorSheet: some View {
        ZStack {
            Theme.Colors.headerBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 44, height: 5)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 10)

                        Text("Personalizar Acesso rápido")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Text("Escolha 3 atalhos para exibir na Área do Professor.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.55))

                        Text("Selecione 3 atalhos.")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))

                        VStack(spacing: 10) {
                            ForEach(TeacherQuickAccessItem.allCases) { item in
                                quickAccessEditorItem(item)
                            }
                        }

                        if let quickAccessEditorError {
                            Text(quickAccessEditorError)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.yellow.opacity(0.85))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }

                HStack(spacing: 12) {
                    Button("Cancelar") {
                        isQuickAccessEditorPresented = false
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.10))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .disabled(isSavingQuickAccessItems)

                    Button {
                        Task { await saveQuickAccessItems() }
                    } label: {
                        HStack(spacing: 10) {
                            if isSavingQuickAccessItems {
                                ProgressView().tint(.white)
                            } else {
                                Text("Salvar")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .primaryGreenActionButton()
                    }
                    .buttonStyle(.plain)
                    .disabled(editableQuickAccessItems.count != 3 || isSavingQuickAccessItems)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
        }
        .interactiveDismissDisabled(isSavingQuickAccessItems)
    }

    private func quickAccessEditorItem(_ item: TeacherQuickAccessItem) -> some View {
        let isSelected = editableQuickAccessItems.contains(item)

        return Button {
            if isSelected {
                editableQuickAccessItems.removeAll { $0 == item }
            } else if editableQuickAccessItems.count < 3 {
                editableQuickAccessItems.append(item)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.green.opacity(0.85))
                    .frame(width: 22)

                Text(item.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .green : .white.opacity(0.35))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.06))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Theme.Colors.primaryGreen.opacity(0.35) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!isSelected && editableQuickAccessItems.count == 3)
    }

    private func openQuickAccessItem(_ item: TeacherQuickAccessItem) {
        switch item {
        case .sendWorkout:
            path.append(
                .teacherSendWorkout(
                    preselectedStudentID: nil,
                    startsAtWorkout: false
                )
            )
        case .createWorkout:
            path.append(.teacherMyWorkouts(category: category, mode: .create))
        case .workoutLibrary:
            path.append(.teacherMyWorkouts(category: category, mode: .library))
        case .importWorkout:
            path.append(.teacherImportWorkouts(category: category))
        case .personalRecords:
            path.append(.teacherPersonalRecords(category: category))
        case .myVideos:
            path.append(.teacherImportVideos(category: category))
        }
    }

    private func loadQuickAccessItems() async {
        guard !isLoadingQuickAccessItems else { return }
        isLoadingQuickAccessItems = true
        defer { isLoadingQuickAccessItems = false }

        guard let teacherId = session.uid?.trimmingCharacters(in: .whitespacesAndNewlines),
              !teacherId.isEmpty else {
            quickAccessItems = TeacherQuickAccessItem.defaultItems
            return
        }

        do {
            let savedItems = try await FirestoreRepository.shared
                .getTeacherQuickAccessItems(uid: teacherId)
            quickAccessItems = validQuickAccessItems(from: savedItems)
                ?? TeacherQuickAccessItem.defaultItems
        } catch {
            quickAccessItems = TeacherQuickAccessItem.defaultItems
        }
    }

    private func saveQuickAccessItems() async {
        guard let teacherId = session.uid?.trimmingCharacters(in: .whitespacesAndNewlines),
              !teacherId.isEmpty else {
            quickAccessEditorError = "Não foi possível identificar o professor logado."
            return
        }
        guard editableQuickAccessItems.count == 3,
              Set(editableQuickAccessItems).count == 3 else {
            quickAccessEditorError = "Selecione exatamente 3 atalhos."
            return
        }

        isSavingQuickAccessItems = true
        quickAccessEditorError = nil
        defer { isSavingQuickAccessItems = false }

        do {
            try await FirestoreRepository.shared.setTeacherQuickAccessItems(
                uid: teacherId,
                items: editableQuickAccessItems.map(\.rawValue)
            )
            quickAccessItems = editableQuickAccessItems
            isQuickAccessEditorPresented = false
        } catch {
            quickAccessEditorError = error.localizedDescription
        }
    }

    private func validQuickAccessItems(
        from rawItems: [String]?
    ) -> [TeacherQuickAccessItem]? {
        guard let rawItems, rawItems.count == 3 else { return nil }
        let items = rawItems.compactMap(TeacherQuickAccessItem.init(rawValue:))
        guard items.count == 3, Set(items).count == 3 else { return nil }
        return items
    }

    private var greeting: String {
        let name = session.userName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Olá, Professor!" : "Olá, \(name)!"
    }

    private var todayText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE, dd/MM"
        let date = formatter.string(from: Date())
        guard let first = date.first else { return date }
        return first.uppercased() + String(date.dropFirst())
    }

    private func summaryItem(
        value: Int?,
        title: String,
        icon: String,
        iconColor: Color = .green.opacity(0.85)
    ) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(iconColor)

            if isLoadingSummary {
                ProgressView()
                    .tint(.white.opacity(0.92))
                    .frame(height: 24)
            } else {
                Text(value.map(String.init) ?? "—")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white.opacity(0.92))
            }

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.62))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 118)
        .padding(.horizontal, 6)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func loadTodaySummary() async {
        guard !isSummaryLoadInProgress else { return }
        isSummaryLoadInProgress = true
        defer { isSummaryLoadInProgress = false }

        guard let teacherId = session.uid?.trimmingCharacters(in: .whitespacesAndNewlines),
              !teacherId.isEmpty else {
            isLoadingSummary = false
            todaySummary = nil
            return
        }

        isLoadingSummary = true
        defer { isLoadingSummary = false }

        do {
            let studentsByCategory = try await FirestoreRepository.shared.getStudentsGroupedByTeacher(
                teacherId: teacherId
            )

            let linkedStudentIDs = Set(
                studentsByCategory.values
                    .flatMap { $0 }
                    .compactMap { $0.id?.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
            guard !linkedStudentIDs.isEmpty else {
                todaySummary = TodaySummary(
                    studentsWithWorkout: 0,
                    completedStudents: 0,
                    studentsWithoutWorkout: 0
                )
                return
            }

            let publishedWeeks = try await FirestoreRepository.shared.getPublishedWeeksForTeacher(
                teacherId: teacherId
            )
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let weeksForToday = publishedWeeks.filter {
                linkedStudentIDs.contains($0.studentId) && weekCanContainToday($0, today: today, calendar: calendar)
            }

            let repository = FirestoreRepository.shared
            let dayData = try await withThrowingTaskGroup(
                of: (String, [TrainingDayFS], [String: Bool]).self
            ) { group in
                for week in weeksForToday {
                    guard let weekId = week.id?.trimmingCharacters(in: .whitespacesAndNewlines),
                          !weekId.isEmpty else {
                        continue
                    }
                    let studentId = week.studentId
                    group.addTask {
                        async let days = repository.getDaysForWeek(weekId: weekId)
                        async let completionMap = repository.getDayStatusMap(
                            weekId: weekId,
                            studentId: studentId
                        )
                        let (loadedDays, loadedCompletionMap) = try await (days, completionMap)
                        return (studentId, loadedDays, loadedCompletionMap)
                    }
                }

                var results: [(String, [TrainingDayFS], [String: Bool])] = []
                for try await result in group {
                    results.append(result)
                }
                return results
            }

            var todayWorkoutsByStudent: [String: [Bool]] = [:]

            for (studentId, days, completionMap) in dayData {
                let todayDays = days.filter {
                    guard let date = $0.date else { return false }
                    return calendar.isDate(date, inSameDayAs: today)
                }
                guard !todayDays.isEmpty else { continue }

                todayWorkoutsByStudent[studentId, default: []].append(
                    contentsOf: todayDays.map { day in
                        day.id.flatMap { completionMap[$0] } == true
                    }
                )
            }

            let studentsWithWorkout = todayWorkoutsByStudent.keys
            let completedStudents = todayWorkoutsByStudent.values.filter { workouts in
                !workouts.isEmpty && workouts.allSatisfy { $0 }
            }.count

            todaySummary = TodaySummary(
                studentsWithWorkout: studentsWithWorkout.count,
                completedStudents: completedStudents,
                studentsWithoutWorkout: max(0, linkedStudentIDs.count - studentsWithWorkout.count)
            )
        } catch {
            #if DEBUG
            print("[TeacherDashboard] Não foi possível carregar o resumo de hoje: \(error.localizedDescription)")
            #endif
            todaySummary = nil
        }
    }

    private func weekCanContainToday(
        _ week: TrainingWeekFS,
        today: Date,
        calendar: Calendar
    ) -> Bool {
        guard let startDate = week.startDate else { return true }
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(
            for: week.endDate ?? calendar.date(byAdding: .day, value: 6, to: start) ?? start
        )
        return today >= start && today <= end
    }

    private func quickAccessItem(
        title: String,
        subtitle: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.green.opacity(0.85))
                    .font(.system(size: 16))
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(2)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(3)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))
                    .font(.system(size: 12, weight: .semibold))
            }
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.06))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
