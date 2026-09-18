// StudentWorkoutsView.swift — Treinos do aluno organizados por semanas e dias
import SwiftUI
import Combine
import UIKit

struct StudentWorkoutsView: View {

    // Bindings, parâmetros e ViewModel
    @Binding var path: [AppRoute]
    let studentId: String
    let studentName: String
    let initialExpandedWeekId: String?
    let initialExpandedDayId: String?
    let onInitialExpansionHandled: () -> Void

    /// Presente apenas quando esta view é a raiz da seção Treinos dentro de
    /// `StudentRootView`. Permite ao rodapé trocar de seção principal sem
    /// tocar em nenhum NavigationStack.
    var onSelectSection: (StudentMainSection) -> Void = { _ in }

    @EnvironmentObject private var session: AppSession

    @AppStorage("ultimoTreinoSelecionado")
    private var ultimoTreinoSelecionado: String = TreinoTipo.crossfit.rawValue

    @StateObject private var vm: StudentWorkoutsViewModel
    private let contentMaxWidth: CGFloat = 380

    private enum WorkoutsFilter: Equatable {
        case active
        case completed
        case all
    }

    private struct TrainingDayGroup: Identifiable {
        let id: String
        let date: Date?
        var days: [TrainingDayFS]
    }

    @State private var selectedFilter: WorkoutsFilter = .active
    @State private var expandedWeekIds = Set<String>()
    @State private var expandedDayIds = Set<String>()
    @State private var hasAppliedInitialExpansion = false

    init(
        path: Binding<[AppRoute]>,
        studentId: String,
        studentName: String,
        initialExpandedWeekId: String? = nil,
        initialExpandedDayId: String? = nil,
        onInitialExpansionHandled: @escaping () -> Void = {},
        onSelectSection: @escaping (StudentMainSection) -> Void = { _ in },
        repository: FirestoreRepository = .shared
    ) {
        self._path = path
        self.studentId = studentId
        self.studentName = studentName
        self.initialExpandedWeekId = initialExpandedWeekId
        self.initialExpandedDayId = initialExpandedDayId
        self.onInitialExpansionHandled = onInitialExpansionHandled
        self.onSelectSection = onSelectSection
        _vm = StateObject(wrappedValue: StudentWorkoutsViewModel(studentId: studentId, repository: repository))
    }

    private var isTeacherViewing: Bool { session.userType == .TRAINER }
    private var teacherSelectedCategory: TreinoTipo {
        TreinoTipo(rawValue: ultimoTreinoSelecionado) ?? .crossfit
    }

    // Corpo com header, conteúdo (cards) e footer
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
                        filterRow
                        if isTeacherViewing {
                            publishWorkoutButton
                        }
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

            ToolbarItem(placement: .topBarLeading) {
                Button(action: handleBack) {
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
                Text("Treinos")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            // Avatar no cabeçalho mostrando foto do usuário
            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
                    .background(Color.clear)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)

        .task(id: studentId) {
            await loadInitialData()
        }
        .onAppear {
            guard vm.hasLoadedWeeks else { return }
            Task {
                await vm.loadWeeksAndMeta(
                    force: true,
                    filterByActiveTeacherLinks: !isTeacherViewing
                )
            }
        }
        .onChange(of: vm.weeks) { _, _ in
            applyInitialExpansionIfNeeded()
        }
    }

    // Footer que varia conforme o usuário (professor/aluno)
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
                    kind: .studentHomeTreinosRecordsProfile(
                        isHomeSelected: false,
                        isTreinosSelected: true,
                        isRecordsSelected: false,
                        isPerfilSelected: false
                    ),
                    onSelectStudentSection: onSelectSection
                )
            }
        }
        .frame(height: Theme.Layout.footerHeight)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.footerBackground)
    }

    // Header informativo
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {

            Text("Selecione uma semana para ver os dias.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var publishWorkoutButton: some View {
        Button {
            path.append(
                .teacherSendWorkout(
                    preselectedStudentID: studentId,
                    startsAtWorkout: true
                )
            )
        } label: {
            HStack {
                Spacer()
                Text("Publicar Treino")
                Spacer()
            }
            .primaryGreenActionButton()
        }
        .buttonStyle(.plain)
    }

    private var filterRow: some View {
        HStack(spacing: 8) {
            filterChip(title: "Ativos", filter: .active)
            filterChip(title: "Concluídos", filter: .completed)
            filterChip(title: "Todos", filter: .all)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func filterChip(title: String, filter: WorkoutsFilter) -> some View {
        Button {
            selectedFilter = filter
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.vertical, 9)
                .background(selectedFilter == filter ? Theme.Colors.primaryGreen.opacity(0.18) : Color.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            selectedFilter == filter ? Theme.Colors.primaryGreen.opacity(0.30) : Color.white.opacity(0.12),
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // Conteúdo principal com estados (loading / error / empty / list)
    private var contentCard: some View {
        VStack(spacing: 0) {
            if vm.weeks.isEmpty && (!vm.hasLoadedWeeks || vm.isLoading) {
                loadingView
            } else if vm.weeks.isEmpty, let errorMessage = vm.errorMessage {
                errorView(message: errorMessage)
            } else if vm.weeks.isEmpty {
                emptyView
            } else if selectedFilter != .all && !vm.hasLoadedWeekMetadata {
                loadingView
            } else if filteredWeeks.isEmpty {
                filteredEmptyView
            } else {
                weeksList(filteredWeeks)
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }

    private var filteredWeeks: [TrainingWeekFS] {
        switch selectedFilter {
        case .active:
            return vm.weeks.filter { !vm.isCompleted($0) && !vm.isExpired($0) }
        case .completed:
            return vm.weeks.filter { vm.isCompleted($0) || vm.isExpired($0) }
        case .all:
            return vm.weeks
        }
    }

    private func weeksList(_ weeks: [TrainingWeekFS]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { item in
                let idx = item.offset
                let week = item.element

                if isTeacherViewing {
                    weekNavigationRow(week)
                } else {
                    expandableWeekRow(week)
                }

                if idx < weeks.count - 1 {
                    innerDivider(leading: 54)
                }
            }
        }
    }

    private func weekNavigationRow(_ week: TrainingWeekFS) -> some View {
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
            weekHeaderContent(week: week, isExpanded: false)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func expandableWeekRow(_ week: TrainingWeekFS) -> some View {
        if let weekId = week.id, !weekId.isEmpty {
            let isExpanded = expandedWeekIds.contains(weekId)
            VStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isExpanded {
                            expandedWeekIds.remove(weekId)
                        } else {
                            expandedWeekIds.insert(weekId)
                        }
                    }
                    if !isExpanded {
                        Task {
                            await vm.loadDaysAndStatus(for: weekId)
                            expandInitialDayIfNeeded(in: weekId)
                        }
                    }
                } label: {
                    weekHeaderContent(week: week, isExpanded: isExpanded)
                }
                .buttonStyle(.plain)

                if isExpanded {
                    weekDaysContent(week: week, weekId: weekId)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        } else {
            weekHeaderContent(week: week, isExpanded: false)
        }
    }

    private func weekHeaderContent(week: TrainingWeekFS, isExpanded: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "calendar")
                .font(.system(size: 18))
                .foregroundColor(.green.opacity(0.85))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(week.weekTitle)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.92))

                Text(vm.teacherLineForWeek(week))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.55))

                Text(vm.subtitleForWeek(week))
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.35))
            }

            Spacer()

            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isExpanded ? Theme.Colors.primaryGreen : .white.opacity(0.35))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func weekDaysContent(week: TrainingWeekFS, weekId: String) -> some View {
        if vm.isLoadingDays(for: weekId) {
            ProgressView()
                .tint(Theme.Colors.primaryGreen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
        } else if let message = vm.daysError(for: weekId) {
            VStack(spacing: 8) {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)

                Button("Tentar novamente") {
                    Task { await vm.loadDaysAndStatus(for: weekId, force: true) }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.primaryGreen)
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        } else {
            let days = vm.days(for: weekId)
            let videos = days.filter(isVideoDay)
            let groups = trainingDayGroups(from: days)

            if days.isEmpty {
                Text("O professor ainda não adicionou dias para esta semana.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
            } else {
                VStack(spacing: 10) {
                    if !videos.isEmpty {
                        videoSection(days: videos, week: week, weekId: weekId)
                    }

                    ForEach(groups) { group in
                        trainingDayGroup(group, week: week, weekId: weekId)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private func videoSection(days: [TrainingDayFS], week: TrainingWeekFS, weekId: String) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "video.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text("Vídeos")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
            }
            .foregroundColor(.orange.opacity(0.9))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                trainingDayRow(day, week: week, weekId: weekId, isVideo: true)
                if index < days.count - 1 {
                    innerDivider(leading: 54)
                }
            }
        }
    }

    private func trainingDayGroup(
        _ group: TrainingDayGroup,
        week: TrainingWeekFS,
        weekId: String
    ) -> some View {
        let isExpanded = expandedDayIds.contains(group.id)
        let fallback = group.days.first?.subtitleText ?? ""
        let status = vm.dayStatus(for: group.days, in: weekId)

        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedDayIds.remove(group.id)
                    } else {
                        expandedDayIds.insert(group.id)
                    }
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.primaryGreen)
                        .frame(width: 28)

                    Text(trainingDateSubtitle(for: group.date, fallback: fallback))
                        .font(.system(size: 17, weight: isExpanded ? .semibold : .medium))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Spacer()

                    dayStatusIndicator(status)

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isExpanded ? Theme.Colors.primaryGreen : .white.opacity(0.35))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .contentShape(Rectangle())
                .background(isExpanded ? Theme.Colors.primaryGreen.opacity(0.12) : Color.clear)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    innerDivider(leading: 16)

                    ForEach(Array(group.days.enumerated()), id: \.element.id) { index, day in
                        trainingDayRow(day, week: week, weekId: weekId, isVideo: false)
                        if index < group.days.count - 1 {
                            innerDivider(leading: 54)
                        }
                    }
                }
                .padding(.vertical, 4)
                .background(Theme.Colors.cardBackground)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func trainingDayRow(
        _ day: TrainingDayFS,
        week: TrainingWeekFS,
        weekId: String,
        isVideo: Bool
    ) -> some View {
        HStack(spacing: 14) {
            Button {
                path.append(.studentDayDetail(weekId: weekId, day: day, weekTitle: week.weekTitle))
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: isVideo ? "video.fill" : "dumbbell.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green.opacity(0.85))
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(day.title)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white.opacity(0.92))
                        Text(isVideo ? day.subtitleText : trainingDateSubtitle(for: day.date, fallback: day.subtitleText))
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.35))
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if let dayId = day.id {
                if vm.isOverdue(day, in: weekId) {
                    Label("Em atraso", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red.opacity(0.9))
                        .labelStyle(.titleAndIcon)
                }

                Button {
                    Task { await vm.toggleCompleted(dayId: dayId, in: weekId) }
                } label: {
                    Image(systemName: completionIcon(isVideo: isVideo, isCompleted: vm.isCompleted(dayId: dayId, in: weekId)))
                        .font(.system(size: 20))
                        .foregroundColor(vm.isCompleted(dayId: dayId, in: weekId) ? .green.opacity(0.85) : .white.opacity(0.35))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
            }
        }
        .padding(.leading, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func dayStatusIndicator(_ status: StudentWorkoutDayStatus) -> some View {
        switch status {
        case .completed:
            Label("Concluído", systemImage: "checkmark.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.Colors.primaryGreen)
                .labelStyle(.titleAndIcon)
        case .overdue:
            Label("Em atraso", systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.red.opacity(0.9))
                .labelStyle(.titleAndIcon)
        case .pending:
            EmptyView()
        }
    }

    private func isVideoDay(_ day: TrainingDayFS) -> Bool {
        day.blocks.contains { block in
            block.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare("Vídeo") == .orderedSame
                && YouTubeVideoImporter.extractYoutubeVideoId(
                    from: block.details.trimmingCharacters(in: .whitespacesAndNewlines)
                ) != nil
        }
    }

    private func trainingDayGroups(from days: [TrainingDayFS]) -> [TrainingDayGroup] {
        let ordered = days.filter { !isVideoDay($0) }.enumerated().sorted { lhs, rhs in
            let lhsDate = lhs.element.date ?? .distantFuture
            let rhsDate = rhs.element.date ?? .distantFuture
            if lhsDate != rhsDate { return lhsDate < rhsDate }
            if lhs.element.dayIndex != rhs.element.dayIndex { return lhs.element.dayIndex < rhs.element.dayIndex }
            return lhs.offset < rhs.offset
        }

        return ordered.reduce(into: [TrainingDayGroup]()) { groups, item in
            let id = dayGroupIdentifier(for: item.element, offset: item.offset)
            if let index = groups.firstIndex(where: { $0.id == id }) {
                groups[index].days.append(item.element)
            } else {
                groups.append(
                    TrainingDayGroup(
                        id: id,
                        date: item.element.date.map { Calendar.current.startOfDay(for: $0) },
                        days: [item.element]
                    )
                )
            }
        }
    }

    private func dayGroupIdentifier(for day: TrainingDayFS, offset: Int) -> String {
        if let date = day.date {
            return "date-\(Int(Calendar.current.startOfDay(for: date).timeIntervalSinceReferenceDate))"
        }
        return day.id.map { "undated-\($0)" } ?? "undated-\(day.dayIndex)-\(offset)"
    }

    private func trainingDateSubtitle(for date: Date?, fallback: String) -> String {
        guard let date else { return fallback }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE dd/MM"
        return formatter.string(from: date).capitalized(with: formatter.locale)
    }

    private func completionIcon(isVideo: Bool, isCompleted: Bool) -> String {
        if isVideo {
            return isCompleted ? "checkmark.seal.fill" : "play.circle"
        }
        return isCompleted ? "checkmark.circle.fill" : "circle"
    }

    private func applyInitialExpansionIfNeeded() {
        guard !hasAppliedInitialExpansion,
              let weekId = initialExpandedWeekId,
              vm.weeks.contains(where: { $0.id == weekId }) else {
            return
        }

        hasAppliedInitialExpansion = true
        expandedWeekIds = [weekId]
        onInitialExpansionHandled()
        Task {
            await vm.loadDaysAndStatus(for: weekId)
            expandInitialDayIfNeeded(in: weekId)
        }
    }

    private func expandInitialDayIfNeeded(in weekId: String) {
        guard initialExpandedWeekId == weekId,
              let dayId = initialExpandedDayId,
              let group = trainingDayGroups(from: vm.days(for: weekId)).first(where: {
                  $0.days.contains(where: { $0.id == dayId })
              }) else {
            return
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedDayIds = [group.id]
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

            Button {
                Task {
                    await vm.loadWeeksAndMeta(
                        force: true,
                        filterByActiveTeacherLinks: !isTeacherViewing
                    )
                }
            } label: {
                Text("Tentar novamente")
                    .padding(.horizontal, 14)
                    .primaryGreenActionButton()
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

    private var filteredEmptyView: some View {
        let content: (title: String, message: String) = switch selectedFilter {
        case .active:
            ("Nenhum treino ativo", "Você não possui treinos pendentes a partir de hoje.")
        case .completed:
            ("Nenhum treino concluído", "Treinos concluídos ou com período encerrado aparecerão aqui.")
        case .all:
            ("Nenhuma semana cadastrada", "O professor ainda não publicou treinos para este aluno.")
        }

        return VStack(spacing: 10) {
            Text(content.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text(content.message)
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

    // Volta para tela anterior
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    private func handleBack() {
        if isTeacherViewing {
            pop()
        } else {
            onSelectSection(.home)
        }
    }

    private func loadInitialData() async {
        if isTeacherViewing {
            await vm.loadWeeksAndMeta(filterByActiveTeacherLinks: false)
        } else {
            await vm.loadWeeksAndMeta(filterByActiveTeacherLinks: true)
        }
    }
}
