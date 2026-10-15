// TrainingWeeksView.swift — Treinos do aluno organizados por semanas e dias
import SwiftUI
import Combine
import UIKit

struct TrainingWeeksView: View {

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
    @Environment(\.locale) private var locale

    @AppStorage("ultimoTreinoSelecionado")
    private var ultimoTreinoSelecionado: String = TreinoTipo.crossfit.rawValue

    @StateObject private var vm: StudentWorkoutsViewModel
    private let contentMaxWidth: CGFloat = 380

    private enum WorkoutsFilter: Equatable {
        case active
        case upcoming
        case completed
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
    @State private var hasAppeared = false
    @State private var activeLockedPlayer: LockedPlayerItem? = nil
    @State private var pendingReceivedVideoSave: (
        sourceId: String,
        title: String,
        url: String,
        videoId: String
    )? = nil
    @State private var isReceivedVideoSaveConfirmationPresented = false
    @State private var isSavingReceivedVideo = false
    @State private var receivedVideoSaveMessage: String? = nil
    @State private var receivedVideoSaveSuccessSourceId: String? = nil

    init(
        path: Binding<[AppRoute]>,
        studentId: String,
        studentName: String,
        initialExpandedWeekId: String? = nil,
        initialExpandedDayId: String? = nil,
        onInitialExpansionHandled: @escaping () -> Void = {},
        onSelectSection: @escaping (StudentMainSection) -> Void = { _ in },
        viewModel: StudentWorkoutsViewModel? = nil,
        repository: FirestoreRepository = .shared
    ) {
        self._path = path
        self.studentId = studentId
        self.studentName = studentName
        self.initialExpandedWeekId = initialExpandedWeekId
        self.initialExpandedDayId = initialExpandedDayId
        self.onInitialExpansionHandled = onInitialExpansionHandled
        self.onSelectSection = onSelectSection
        _vm = StateObject(wrappedValue: viewModel ?? StudentWorkoutsViewModel(studentId: studentId, repository: repository))
    }

    // Cores locais exclusivas do Tema Claro desta tela (Tema Escuro usa sempre os valores originais)
    private enum LightColors {
        // Verde quase branco: filtros não selecionados e card do treino individual
        static let chipSurface = Color(red: 0xEE / 255, green: 0xF8 / 255, blue: 0xF0 / 255)
        static let rowSurface = Color(red: 0xF1 / 255, green: 0xF7 / 255, blue: 0xF0 / 255)       // #F1F7F0
        static let rowBorder = Color(red: 0xC4 / 255, green: 0xE7 / 255, blue: 0xCC / 255)        // #C4E7CC
        static let rowSecondaryText = Color(red: 0x77 / 255, green: 0x7D / 255, blue: 0x77 / 255) // #777D77
        static let pendingBorder = Color(red: 0x7E / 255, green: 0x85 / 255, blue: 0x7E / 255)    // #7E857E
        // Card principal da semana (cores solidas, sem mistura com o fundo)
        static let weekSurface = Color(red: 0xF1 / 255, green: 0xF7 / 255, blue: 0xF0 / 255)      // #F1F7F0
        static let cardBorder = Color(red: 0xC9 / 255, green: 0xDF / 255, blue: 0xC9 / 255)       // #C9DFC9
        static let calendarSurface = Color(red: 0x85 / 255, green: 0xC9 / 255, blue: 0x95 / 255)  // #85C995
        static let iconInk = Color(red: 0x25 / 255, green: 0x48 / 255, blue: 0x2B / 255)          // #25482B
        static let pastelSurface = Color(red: 0xDC / 255, green: 0xEE / 255, blue: 0xDD / 255)    // #DCEEDD
        static let militaryText = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)     // #294A2F
        static let progressTrack = Color(red: 0xD5 / 255, green: 0xE2 / 255, blue: 0xD5 / 255)    // #D5E2D5
        // Agrupador do dia: cabecalho pastel mais intenso e area inferior mais clara
        static let dayHeaderSurface = Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255) // #DDEDDC
        static let dayContentSurface = Color(red: 0xF0 / 255, green: 0xF7 / 255, blue: 0xEF / 255) // #F0F7EF
        // Texto principal preto
        static let primaryText = Color(red: 0x17 / 255, green: 0x1C / 255, blue: 0x17 / 255)      // #171C17
        // Bordas discretas
        static let subtleBorder = AppThemePalette.lightCardBorder.opacity(0.55)
    }

    private var isTeacherViewing: Bool { session.isTrainer }
    private var viewingTeacherId: String? {
        isTeacherViewing ? (session.uid ?? "") : nil
    }
    private var teacherSelectedCategory: TreinoTipo {
        TreinoTipo(rawValue: ultimoTreinoSelecionado) ?? .crossfit
    }

    // Corpo com header, conteúdo (cards) e footer
    var body: some View {
        ZStack {

            AppThemeBackgroundImage()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {

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
                            // Tema Escuro: verde original (systemAccentForeground). Tema Claro: branco sobre o cabeçalho verde militar.
                            .foregroundStyle(AppThemeColor(dark: Color.green, light: .white, followsBarColorScheme: false))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("workout.workouts_this_week")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundStyle(Theme.Colors.ink())
            }

            // Avatar no cabeçalho mostrando foto do usuário
            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
                    .background(Color.clear)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appThemeLightHeaderColorScheme()
        .navigationBarTitleDisplayMode(.inline)

        .onAppear {
            let isFirstAppearance = !hasAppeared
            hasAppeared = true
            guard !vm.hasLoadedWeeks else {
                // ViewModel reaproveitado (troca de aba): exibe o cache na hora e
                // apenas revalida a lista de semanas em segundo plano.
                guard isFirstAppearance else { return }
                applyInitialExpansionIfNeeded()
                Task {
                    await vm.revalidateWeeksInBackground(
                        filterByActiveTeacherLinks: !isTeacherViewing,
                        viewingTeacherId: viewingTeacherId
                    )
                }
                return
            }
            Task {
                await vm.loadWeeksAndMeta(
                    filterByActiveTeacherLinks: !isTeacherViewing,
                    viewingTeacherId: viewingTeacherId
                )
            }
        }
        .onChange(of: vm.weeks) { _, _ in
            applyInitialExpansionIfNeeded()
        }
        .fullScreenCover(item: $activeLockedPlayer) { item in
            YoutubeLockedPlayerSheet(title: item.title, videoId: item.videoId)
        }
        .alert(
            "workout.my_videos",
            isPresented: Binding(
                get: { receivedVideoSaveMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        receivedVideoSaveMessage = nil
                    }
                }
            )
        ) {
            Button("common.ok", role: .cancel) {
                receivedVideoSaveMessage = nil
            }
        } message: {
            Text(receivedVideoSaveMessage ?? "")
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
                Text("workout.publish_workout")
                Spacer()
            }
            .primaryGreenActionButton()
        }
        .buttonStyle(.plain)
    }

    private var filterRow: some View {
        HStack(spacing: 8) {
            filterChip(title: "workout.filter.active", filter: .active)
            filterChip(title: "workout.filter.upcoming", filter: .upcoming)
            filterChip(title: "workout.filter.completed", filter: .completed)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func filterChip(title: LocalizedStringKey, filter: WorkoutsFilter) -> some View {
        Button {
            selectedFilter = filter
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(
                    // Tema Claro: texto branco no selecionado (fundo verde militar)
                    selectedFilter == filter
                        ? AppThemeColor(dark: Color.white.opacity(0.92), light: .white)
                        : Theme.Colors.ink(0.92)
                )
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.vertical, 9)
                .background(
                    selectedFilter == filter
                        ? AnyShapeStyle(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.18), light: AppThemePalette.lightBar))
                        : AnyShapeStyle(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.chipSurface))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            selectedFilter == filter
                                ? AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.55), light: AppThemePalette.lightBar)
                                : AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.subtleBorder),
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(
                    color: selectedFilter == filter ? Theme.Colors.primaryGreen.opacity(0.20) : .clear,
                    radius: 8,
                    y: 2
                )
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
            } else if !vm.hasLoadedWeekMetadata {
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
            return vm.weeks.filter {
                !vm.isCompleted($0) && !vm.isExpired($0) && !vm.isUpcoming($0)
            }
        case .upcoming:
            return vm.weeks.filter { vm.isUpcoming($0) }
        case .completed:
            return vm.weeks.filter { vm.isCompleted($0) || vm.isExpired($0) }
        }
    }

    private func weeksList(_ weeks: [TrainingWeekFS]) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { item in
                expandableWeekRow(item.element)
            }
        }
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
        let progressPercent = vm.progressPercent(for: week)
        let progressValue = Double(progressPercent) / 100.0
        let weekId = week.id ?? ""
        let trainingDays = vm.days(for: weekId).filter { !$0.isVideoDay }
        let completedCount = trainingDays.compactMap(\.id)
            .filter { vm.isCompleted(dayId: $0, in: weekId) }
            .count
        let completionFormat = trainingDays.count == 1
            ? AppLocalization.string("dashboard.upcoming_workouts.progress_singular", locale: locale)
            : AppLocalization.string("dashboard.upcoming_workouts.progress_plural", locale: locale)

        return HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11)
                    .fill(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.14), light: LightColors.calendarSurface))
                Image(systemName: "calendar")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppThemeColor(dark: Theme.Colors.primaryGreen, light: LightColors.iconInk))
            }
            .frame(width: 42, height: 42)
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .stroke(
                        AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.22), light: LightColors.cardBorder),
                        lineWidth: 1
                    )
            )

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text(vm.subtitleForWeek(week, locale: locale))
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Theme.Colors.ink(0.92))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer(minLength: 4)

                    Text(
                        String(
                            format: AppLocalization.string("workout.progress_percentage", locale: locale),
                            locale: locale,
                            arguments: [Int64(progressPercent)]
                        )
                    )
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppThemeColor(dark: Theme.Colors.primaryGreen, light: LightColors.militaryText))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.14), light: LightColors.pastelSurface))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(
                                    AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.25), light: LightColors.cardBorder),
                                    lineWidth: 1
                                )
                        )
                }

                HStack(spacing: 8) {
                    Text(vm.teacherLineForWeek(week, locale: locale))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.55), light: AppThemePalette.lightInk))
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    if vm.isUpcoming(week) {
                        Label(LocalizedStringKey("workout.coming_soon"), systemImage: "clock.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.Colors.ink(0.55))
                            .labelStyle(.titleAndIcon)
                            .lineLimit(1)
                    }
                }

                Text(
                    String(
                        format: completionFormat,
                        locale: locale,
                        arguments: [Int64(completedCount), Int64(trainingDays.count)]
                    )
                )
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.ink(0.55))

                ProgressView(value: progressValue)
                    .tint(AppThemeColor(dark: Theme.Colors.primaryGreen, light: AppThemePalette.lightAccent))
                    // Tema Claro: trilho verde-acinzentado sólido (Tema Escuro: transparente, sem alteração)
                    .background(
                        Capsule().fill(AppThemeColor(dark: .clear, light: LightColors.progressTrack))
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppThemeColor(dark: isExpanded ? Theme.Colors.primaryGreen : .white.opacity(0.35), light: LightColors.militaryText))
                .padding(.top, 14)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.weekSurface))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    AppThemeColor(
                        dark: Theme.Colors.primaryGreen.opacity(isExpanded ? 0.42 : 0.28),
                        light: LightColors.cardBorder
                    ),
                    lineWidth: 1
                )
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
                    .foregroundStyle(Theme.Colors.ink(0.55))
                    .multilineTextAlignment(.center)

                Button("dashboard.try_again_action") {
                    Task { await vm.loadDaysAndStatus(for: weekId, force: true) }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.Colors.accentForeground)
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        } else {
            let days = vm.days(for: weekId)
            let videos = days.filter(\.isVideoDay)
            let groups = trainingDayGroups(from: days)

            if days.isEmpty {
                Text("workout.the_coach_has_not_added_days_for_this_week_yet")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.ink(0.55))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
            } else {
                VStack(spacing: 10) {
                    if !videos.isEmpty {
                        videoSection(days: videos)
                    }

                    ForEach(groups) { group in
                        trainingDayGroup(group, week: week, weekId: weekId)
                    }
                }
                .padding(.top, 10)
            }
        }
    }

    private func videoSection(days: [TrainingDayFS]) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "video.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Colors.icon(.orange.opacity(0.9)))
                Text("workout.videos")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
            }
            .foregroundColor(.orange.opacity(0.9))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                if let video = youtubeVideoInfo(for: day) {
                    videoCard(for: day, videoId: video.videoId, videoURL: video.url)
                }
                if index < days.count - 1 {
                    innerDivider(leading: 14)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.Colors.cardBorder, lineWidth: 1)
        )
    }

    private func youtubeVideoInfo(for day: TrainingDayFS) -> (videoId: String, url: String)? {
        for block in day.blocks {
            let name = block.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard name.caseInsensitiveCompare("Vídeo") == .orderedSame else { continue }

            let url = block.details.trimmingCharacters(in: .whitespacesAndNewlines)
            if let videoId = YouTubeVideoImporter.extractYoutubeVideoId(from: url) {
                return (videoId, url)
            }
        }

        return nil
    }

    private func videoCard(for day: TrainingDayFS, videoId: String, videoURL: String) -> some View {
        let sourceId = day.id ?? "\(day.dayIndex)-\(videoId)"

        return HStack(spacing: 12) {
            videoThumbnail(videoId: videoId)

            VStack(alignment: .leading, spacing: 4) {
                let title = day.title.trimmingCharacters(in: .whitespacesAndNewlines)
                Text(title.isEmpty ? AppLocalization.string("workout.youtube_video", locale: locale) : title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink(0.92))
                    .lineLimit(1)

                Text("workout.youtube")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.ink(0.55))
                    .lineLimit(1)
            }

            Spacer()

            if !isTeacherViewing {
                Menu {
                    Button {
                        let title = day.title.trimmingCharacters(in: .whitespacesAndNewlines)
                        pendingReceivedVideoSave = (
                            sourceId: sourceId,
                            title: title.isEmpty ? AppLocalization.string("workout.youtube_video", locale: locale) : title,
                            url: videoURL,
                            videoId: videoId
                        )
                        isReceivedVideoSaveConfirmationPresented = true
                    } label: {
                        Label(LocalizedStringKey("workout.save_to_my_videos"), systemImage: "bookmark")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.Colors.icon(Theme.Colors.ink(0.55)))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isSavingReceivedVideo)
                .popover(
                    isPresented: Binding(
                        get: {
                            (isReceivedVideoSaveConfirmationPresented
                                && pendingReceivedVideoSave?.sourceId == sourceId)
                                || receivedVideoSaveSuccessSourceId == sourceId
                        },
                        set: { isPresented in
                            if !isPresented {
                                if pendingReceivedVideoSave?.sourceId == sourceId {
                                    isReceivedVideoSaveConfirmationPresented = false
                                    pendingReceivedVideoSave = nil
                                }
                                if receivedVideoSaveSuccessSourceId == sourceId {
                                    receivedVideoSaveSuccessSourceId = nil
                                }
                            }
                        }
                    ),
                    arrowEdge: .bottom
                ) {
                    Group {
                        if receivedVideoSaveSuccessSourceId == sourceId {
                            receivedVideoSaveSuccessCard(sourceId: sourceId)
                        } else {
                            receivedVideoSaveConfirmationCard
                        }
                    }
                    .presentationCompactAdaptation(.popover)
                }
            }

            Button {
                openLockedPlayer(for: day, videoId: videoId)
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.Colors.chevron(0.35))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture {
            openLockedPlayer(for: day, videoId: videoId)
        }
    }

    private var receivedVideoSaveConfirmationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("workout.save_to_my_videos")
                .font(.system(size: 17, weight: .semibold))

            Text("workout.do_you_want_to_save_this_video_to_your_my_videos_list")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            HStack {
                Button("common.cancel", role: .cancel) {
                    isReceivedVideoSaveConfirmationPresented = false
                    pendingReceivedVideoSave = nil
                }

                Spacer()

                Button("common.save") {
                    guard let video = pendingReceivedVideoSave else { return }
                    isReceivedVideoSaveConfirmationPresented = false
                    pendingReceivedVideoSave = nil
                    Task { await saveReceivedVideoToMyVideos(video) }
                }
            }
        }
        .padding(16)
        .frame(width: 300, alignment: .leading)
    }

    private func receivedVideoSaveSuccessCard(sourceId: String) -> some View {
        Text("workout.video_saved_to_my_videos")
            .font(.system(size: 14, weight: .semibold))
            .padding(16)
            .frame(width: 240, alignment: .leading)
            .task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard !Task.isCancelled, receivedVideoSaveSuccessSourceId == sourceId else { return }
                receivedVideoSaveSuccessSourceId = nil
            }
    }

    @MainActor
    private func saveReceivedVideoToMyVideos(
        _ video: (sourceId: String, title: String, url: String, videoId: String)
    ) async {
        guard !isTeacherViewing else { return }

        let expectedStudentId = studentId.trimmingCharacters(in: .whitespacesAndNewlines)
        let authenticatedStudentId = (session.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !expectedStudentId.isEmpty, expectedStudentId == authenticatedStudentId else {
            receivedVideoSaveMessage = AppLocalization.string(
                "workout.video_save_authentication_error",
                locale: locale
            )
            return
        }

        isSavingReceivedVideo = true
        defer { isSavingReceivedVideo = false }

        do {
            let savedVideos = try await YoutubeVideosRepository.loadStudentVideos(
                studentId: authenticatedStudentId
            )
            guard !savedVideos.contains(where: { $0.videoId == video.videoId }) else {
                receivedVideoSaveMessage = AppLocalization.string(
                    "workout.video_already_saved",
                    locale: locale
                )
                return
            }

            try await YoutubeVideosRepository.addStudentVideo(
                studentId: authenticatedStudentId,
                title: video.title,
                url: video.url,
                videoCategory: .crossfit,
                locale: locale
            )
            receivedVideoSaveSuccessSourceId = video.sourceId
        } catch {
            receivedVideoSaveMessage = error.localizedDescription
        }
    }

    private func openLockedPlayer(for day: TrainingDayFS, videoId: String) {
        let title = day.title.trimmingCharacters(in: .whitespacesAndNewlines)
        activeLockedPlayer = LockedPlayerItem(
            title: title.isEmpty ? AppLocalization.string("workout.youtube_video", locale: locale) : title,
            videoId: videoId
        )
    }

    private func videoThumbnail(videoId: String) -> some View {
        let thumbnailURL = "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg"

        return ZStack(alignment: .bottomTrailing) {
            AsyncImage(url: URL(string: thumbnailURL)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Theme.Colors.ink(0.06)
                        ProgressView().tint(Theme.Colors.ink(0.8))
                    }
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    ZStack {
                        Theme.Colors.ink(0.06)
                        Image(systemName: "video.fill")
                            .foregroundStyle(Theme.Colors.icon(Theme.Colors.systemAccentForeground(0.85)))
                    }
                @unknown default:
                    Theme.Colors.ink(0.06)
                }
            }
            .frame(width: 66, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.Colors.ink(0.10), lineWidth: 1)
            )

            ZStack {
                Circle()
                    .fill(Theme.Colors.glass(0.45))
                Image(systemName: "play.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.Colors.icon(Theme.Colors.ink(0.95)))
                    .padding(.leading, 1)
            }
            .frame(width: 18, height: 18)
            .overlay(
                Circle()
                    .stroke(Theme.Colors.ink(0.18), lineWidth: 1)
            )
            .padding(6)
        }
    }

    private func trainingDayGroup(
        _ group: TrainingDayGroup,
        week: TrainingWeekFS,
        weekId: String
    ) -> some View {
        let isExpanded = expandedDayIds.contains(group.id)
        let fallback = group.days.first?.subtitleText(locale: locale) ?? ""
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
                    ZStack {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.14), light: LightColors.calendarSurface))
                        Image(systemName: "calendar")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppThemeColor(dark: Theme.Colors.primaryGreen, light: LightColors.iconInk))
                    }
                    .frame(width: 34, height: 34)

                    Text(trainingDateSubtitle(for: group.date, fallback: fallback))
                        .font(.system(size: 17, weight: isExpanded ? .semibold : .medium))
                        .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Spacer()

                    dayStatusIndicator(status)

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppThemeColor(dark: isExpanded ? Theme.Colors.primaryGreen : .white.opacity(0.35), light: LightColors.militaryText))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
                // Tema Escuro: expressão original. Tema Claro: verde pastel suave, igual nos estados expandido/recolhido.
                .background(
                    AppThemeColor(
                        dark: isExpanded ? Theme.Colors.primaryGreen.opacity(0.14) : Color.black.opacity(0.54),
                        light: LightColors.dayHeaderSurface
                    )
                )
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(Array(group.days.enumerated()), id: \.element.id) { item in
                        trainingDayRow(item.element, week: week, weekId: weekId)
                    }
                }
                .padding(10)
                .background(AppThemeColor(dark: Color.black.opacity(0.40), light: LightColors.dayContentSurface))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.dayContentSurface))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    AppThemeColor(
                        dark: isExpanded ? Theme.Colors.primaryGreen.opacity(0.40) : Theme.Colors.primaryGreen.opacity(0.28),
                        light: LightColors.cardBorder
                    ),
                    lineWidth: 1
                )
        )
    }

    private func trainingDayRow(
        _ day: TrainingDayFS,
        week: TrainingWeekFS,
        weekId: String
    ) -> some View {
        HStack(spacing: 12) {
            Button {
                path.append(.studentDayDetail(weekId: weekId, day: day, weekTitle: week.weekTitle))
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.14), light: LightColors.pastelSurface))
                        Image(systemName: workoutIconName(for: day, in: week))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppThemeColor(dark: Theme.Colors.primaryGreen, light: LightColors.iconInk))
                    }
                    .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(DefaultWorkoutLocalization.presentation(for: day, locale: locale).title)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                        Text(trainingDateSubtitle(for: day.date, fallback: day.subtitleText(locale: locale)))
                            .font(.system(size: 14))
                            .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.35), light: LightColors.rowSecondaryText))
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !isTeacherViewing, let dayId = day.id, !vm.isUpcoming(week) {
                if vm.isOverdue(day, in: weekId) {
                    Label(LocalizedStringKey("workout.overdue"), systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red.opacity(0.9))
                        .labelStyle(.titleAndIcon)
                }

                let isCompleted = vm.isCompleted(dayId: dayId, in: weekId)
                Button {
                    Task { await vm.toggleCompleted(dayId: dayId, in: weekId, locale: locale) }
                } label: {
                    ZStack {
                        Circle()
                            .fill(isCompleted ? Theme.Colors.primaryGreen : .clear)
                        Circle()
                            .stroke(
                                // Tema Claro: borda cinza-esverdeada quando pendente; concluído mantém o verde original
                                isCompleted
                                    ? AppThemeColor(dark: Theme.Colors.primaryGreen, light: Theme.Colors.primaryGreen)
                                    : AppThemeColor(dark: Color.white.opacity(0.35), light: LightColors.pendingBorder),
                                lineWidth: 1.5
                            )
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.black.opacity(0.78))
                        }
                    }
                    .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.rowSurface))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.rowBorder),
                    lineWidth: 1
                )
        )
    }

    @ViewBuilder
    private func dayStatusIndicator(_ status: StudentWorkoutDayStatus) -> some View {
        switch status {
        case .completed:
            Label(LocalizedStringKey("common.done"), systemImage: "checkmark.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.Colors.accentForeground)
                .labelStyle(.titleAndIcon)
        case .overdue:
            Label(LocalizedStringKey("workout.overdue"), systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.red.opacity(0.9))
                .labelStyle(.titleAndIcon)
        case .pending:
            EmptyView()
        }
    }

    private func trainingDayGroups(from days: [TrainingDayFS]) -> [TrainingDayGroup] {
        let ordered = days.filter { !$0.isVideoDay }.enumerated().sorted { lhs, rhs in
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
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("EEEEddMM")
        return formatter.string(from: date).capitalized(with: formatter.locale)
    }

    private func workoutIconName(for day: TrainingDayFS, in week: TrainingWeekFS) -> String {
        let category = day.categoryRaw
            .flatMap { TreinoTipo.normalized(from: $0) }
            ?? TreinoTipo.normalized(from: week.categoryRaw)

        guard let category else {
            return "dumbbell.fill"
        }

        switch category {
        case .crossfit:
            return "figure.strengthtraining.traditional"
        case .academia:
            return "dumbbell"
        case .emCasa:
            return "house.fill"
        }
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
            Text("workout.loading_weeks")
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.ink(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 10) {
            Text("workout.oops_unable_to_load")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink(0.92))

            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.ink(0.55))
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await vm.loadWeeksAndMeta(
                        force: true,
                        filterByActiveTeacherLinks: !isTeacherViewing,
                        viewingTeacherId: viewingTeacherId
                    )
                }
            } label: {
                Text("dashboard.try_again_action")
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
            Text("workout.no_week_registered")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink(0.92))

            Text("workout.the_coach_has_not_published_workouts_for_this_student_yet")
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.ink(0.55))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 10)
    }

    private var filteredEmptyView: some View {
        let content: (title: LocalizedStringKey, message: LocalizedStringKey) = switch selectedFilter {
        case .active:
            ("workout.empty.active.title", "workout.empty.active.message")
        case .upcoming:
            ("workout.empty.upcoming.title", "workout.empty.upcoming.message")
        case .completed:
            ("workout.empty.completed.title", "workout.empty.completed.message")
        }

        return VStack(spacing: 10) {
            Text(content.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink(0.92))

            Text(content.message)
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.ink(0.55))
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

}
