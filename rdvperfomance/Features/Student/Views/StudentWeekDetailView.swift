// StudentWeekDetailView.swift — Exibe dias de uma semana com opção de marcar conclusão e navegação para detalhes
import SwiftUI
import Combine
import UIKit
import Foundation

struct StudentWeekDetailView: View {

    @Binding var path: [AppRoute]

    let studentId: String
    let weekId: String
    let weekTitle: String
    let initialExpandedDayId: String?

    /// Presente apenas no contexto de aluno (dentro de `StudentRootView`).
    var onSelectSection: (StudentMainSection) -> Void = { _ in }

    @EnvironmentObject private var session: AppSession

    @AppStorage("ultimoTreinoSelecionado")
    private var ultimoTreinoSelecionado: String = TreinoTipo.crossfit.rawValue

    @StateObject private var vm: StudentWeekDetailViewModel
    private let contentMaxWidth: CGFloat = 380

    // ✅ Animação quando tudo estiver concluído
    @State private var showWeekCompletedAnimation: Bool = false
    @State private var hasTriggeredWeekCompletedAnimation: Bool = false
    @State private var expandedDayIds = Set<String>()
    @State private var hasInitializedExpandedDays = false

    private struct TrainingDayGroup: Identifiable {
        let id: String
        let date: Date?
        var items: [(offset: Int, day: TrainingDayFS)]
    }

    init(
        path: Binding<[AppRoute]>,
        studentId: String,
        weekId: String,
        weekTitle: String,
        initialExpandedDayId: String? = nil,
        onSelectSection: @escaping (StudentMainSection) -> Void = { _ in },
        repository: FirestoreRepository = .shared
    ) {
        self._path = path
        self.studentId = studentId
        self.weekId = weekId
        self.weekTitle = weekTitle
        self.initialExpandedDayId = initialExpandedDayId
        self.onSelectSection = onSelectSection
        _vm = StateObject(wrappedValue: StudentWeekDetailViewModel(weekId: weekId, studentId: studentId, repository: repository))
    }

    private var isTeacherViewing: Bool { session.userType == .TRAINER }
    private var isStudentViewing: Bool { session.userType == .STUDENT }

    private var teacherSelectedCategory: TreinoTipo {
        TreinoTipo(rawValue: ultimoTreinoSelecionado) ?? .crossfit
    }

    // ✅ Detecta se o dia possui um bloco "Vídeo" com link válido do YouTube
    private func isVideoDay(_ day: TrainingDayFS) -> Bool {
        day.blocks.contains { block in
            let nameTrim = block.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard nameTrim.caseInsensitiveCompare("Vídeo") == .orderedSame else { return false }

            let urlTrim = block.details.trimmingCharacters(in: .whitespacesAndNewlines)
            return YouTubeVideoImporter.extractYoutubeVideoId(from: urlTrim) != nil
        }
    }

    // Mantém vídeos no bloco próprio e ordena os treinos cronologicamente.
    private var orderedDays: [(offset: Int, day: TrainingDayFS)] {
        let enumerated = Array(vm.days.enumerated()).map { (offset: $0.offset, day: $0.element) }
        return enumerated.sorted { a, b in
            let aIsVideo = isVideoDay(a.day)
            let bIsVideo = isVideoDay(b.day)
            if aIsVideo != bIsVideo { return aIsVideo && !bIsVideo }
            if !aIsVideo {
                let aDate = a.day.date ?? .distantFuture
                let bDate = b.day.date ?? .distantFuture
                if aDate != bDate { return aDate < bDate }
                if a.day.dayIndex != b.day.dayIndex { return a.day.dayIndex < b.day.dayIndex }
            }
            return a.offset < b.offset
        }
    }

    // Mantém vídeos separados dos treinos para preservar sua apresentação específica.
    private var videoDays: [(offset: Int, day: TrainingDayFS)] {
        orderedDays.filter { isVideoDay($0.day) }
    }

    private var trainingDays: [(offset: Int, day: TrainingDayFS)] {
        orderedDays.filter { !isVideoDay($0.day) }
    }

    private var trainingDayGroups: [TrainingDayGroup] {
        var groups: [TrainingDayGroup] = []
        var groupIndexes = [String: Int]()

        for item in trainingDays {
            let identifier = groupIdentifier(for: item.day, offset: item.offset)
            if let index = groupIndexes[identifier] {
                groups[index].items.append(item)
            } else {
                groupIndexes[identifier] = groups.count
                groups.append(
                    TrainingDayGroup(
                        id: identifier,
                        date: item.day.date.map { Calendar.current.startOfDay(for: $0) },
                        items: [item]
                    )
                )
            }
        }

        return groups
    }

    private var hasAnyVideo: Bool { !videoDays.isEmpty }

    // ✅ Todos os registros concluídos (para aluno): se todos os dias com id estiverem marcados como concluídos
    private var allWeekCompleted: Bool {
        guard isStudentViewing else { return false }
        let ids = vm.days.compactMap { $0.id }
        guard !ids.isEmpty else { return false }
        return ids.allSatisfy { vm.isCompleted(dayId: $0) }
    }

    // Corpo principal com header, lista de dias e footer
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

            // ✅ Animação/overlay quando concluir toda a semana
            if showWeekCompletedAnimation {
                weekCompletedOverlay
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(10)
            }
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
                Text("Semana")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            // Avatar no cabeçalho (foto real do usuário)
            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)

        .onAppear {
            Task {
                if !vm.isLoading {
                    await vm.loadDaysAndStatus()
                }
            }
        }
        // ✅ Dispara animação quando todos os registros forem concluídos
        .onChange(of: allWeekCompleted) { _, newValue in
            guard newValue else {
                hasTriggeredWeekCompletedAnimation = false
                return
            }
            guard !hasTriggeredWeekCompletedAnimation else { return }
            hasTriggeredWeekCompletedAnimation = true
            triggerWeekCompletedAnimation()
        }
        .onChange(of: vm.days) { _, days in
            initializeExpandedDays(with: days)
        }
    }

    // Footer adaptado por tipo de usuário
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

    // Header com título e CTA para professor quando não houver dias
    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text(weekTitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text(isStudentViewing ? "Marque os dias como concluídos." : "Dias de treino")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.35))

            if isTeacherViewing && !vm.isLoading && vm.days.isEmpty {
                Button {
                    path.append(.createTrainingDay(weekId: weekId, category: teacherSelectedCategory))
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus")
                        Text("Adicionar primeiro dia")
                    }
                    .padding(.horizontal, 14)
                    .primaryGreenActionButton()
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Conteúdo principal mantém os estados de loading, erro e vazio antes da lista de dias.
    private var contentCard: some View {
        VStack(spacing: 0) {

            if vm.isLoading {
                loadingView
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(14)

            } else if let errorMessage = vm.errorMessage {
                errorView(message: errorMessage)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(14)

            } else if vm.days.isEmpty {
                emptyView
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(14)

            } else {
                daysCards
            }
        }
    }

    // ✅ Cabeçalho de seção (laranja)
    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.orange.opacity(0.9))
                .frame(width: 18)

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.orange.opacity(0.9))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // ✅ Ícone de check diferente para vídeo: representa “assistido”
    private func completionIcon(isVideo: Bool, isCompleted: Bool) -> (name: String, color: Color) {
        if isVideo {
            return (isCompleted ? "checkmark.seal.fill" : "play.circle", isCompleted ? .green.opacity(0.85) : .white.opacity(0.35))
        } else {
            return (isCompleted ? "checkmark.circle.fill" : "circle", isCompleted ? .green.opacity(0.85) : .white.opacity(0.35))
        }
    }

    private var daysCards: some View {
        VStack(spacing: 16) {
            if hasAnyVideo {
                daysSectionCard(
                    title: "Vídeos",
                    systemImage: "video.fill",
                    items: videoDays
                )
            }

            ForEach(trainingDayGroups) { group in
                trainingDayCard(group: group)
            }
        }
    }

    private func daysSectionCard(
        title: String,
        systemImage: String,
        items: [(offset: Int, day: TrainingDayFS)]
    ) -> some View {

        VStack(alignment: .leading, spacing: 10) {

            // Mantém header em laranja (ícone + texto)
            sectionHeader(title, systemImage: systemImage)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.offset) { idx, it in
                    let day = it.day
                    let isVideo = isVideoDay(day)

                    HStack(spacing: 14) {

                        Image(systemName: isVideo ? "video.fill" : "dumbbell.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green.opacity(0.85))
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(day.title)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.92))

                            Text(
                                isVideo
                                    ? day.subtitleText
                                    : trainingDateSubtitle(for: day.date, fallback: day.subtitleText)
                            )
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.35))
                        }

                        Spacer()

                        if isStudentViewing, let dayId = day.id {
                            Button {
                                Task {
                                    await vm.toggleCompleted(dayId: dayId)

                                    if allWeekCompleted && !hasTriggeredWeekCompletedAnimation {
                                        hasTriggeredWeekCompletedAnimation = true
                                        triggerWeekCompletedAnimation()
                                    }
                                }
                            } label: {
                                let completed = vm.isCompleted(dayId: dayId)
                                let icon = completionIcon(isVideo: isVideo, isCompleted: completed)

                                Image(systemName: icon.name)
                                    .font(.system(size: 20))
                                    .foregroundColor(icon.color)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 6)
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.35))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        path.append(.studentDayDetail(weekId: weekId, day: day, weekTitle: weekTitle))
                    }

                    if idx < items.count - 1 {
                        innerDivider(leading: 54)
                    }
                }
            }
        }
        .padding(.horizontal, 0) // conteúdo já tem padding nas rows
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)   // ✅ aqui é o “bloco/card” de verdade
        .cornerRadius(14)
    }

    private func trainingDayCard(group: TrainingDayGroup) -> some View {
        let isExpanded = expandedDayIds.contains(group.id)
        let fallbackTitle = group.items.first?.day.subtitleText ?? ""

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

                    Text(trainingDateSubtitle(for: group.date, fallback: fallbackTitle))
                        .font(.system(size: 18, weight: isExpanded ? .semibold : .medium))
                        .foregroundColor(.white.opacity(0.92))

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isExpanded ? Theme.Colors.primaryGreen : .white.opacity(0.35))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
                .background(isExpanded ? Theme.Colors.primaryGreen.opacity(0.12) : Color.clear)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(group.items.enumerated()), id: \.element.offset) { index, item in
                        trainingDayRow(item.day)

                        if index < group.items.count - 1 {
                            innerDivider(leading: 54)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func trainingDayRow(_ day: TrainingDayFS) -> some View {
        HStack(spacing: 14) {
            Button {
                path.append(.studentDayDetail(weekId: weekId, day: day, weekTitle: weekTitle))
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green.opacity(0.85))
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(day.title)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.92))

                        Text(day.subtitleText)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.35))
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isStudentViewing, let dayId = day.id {
                Button {
                    Task {
                        await vm.toggleCompleted(dayId: dayId)

                        if allWeekCompleted && !hasTriggeredWeekCompletedAnimation {
                            hasTriggeredWeekCompletedAnimation = true
                            triggerWeekCompletedAnimation()
                        }
                    }
                } label: {
                    let completed = vm.isCompleted(dayId: dayId)
                    let icon = completionIcon(isVideo: false, isCompleted: completed)

                    Image(systemName: icon.name)
                        .font(.system(size: 20))
                        .foregroundColor(icon.color)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var loadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("Carregando dias...")
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

            Button { Task { await vm.loadDaysAndStatus() } } label: {
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
            Text("Nenhum dia cadastrado")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text(isTeacherViewing
                 ? "Adicione dias para esta semana."
                 : "O professor ainda não adicionou dias para esta semana.")
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

    private func trainingDateSubtitle(for date: Date?, fallback: String) -> String {
        guard let date else { return fallback }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE dd/MM"
        return formatter.string(from: date).capitalized(with: formatter.locale)
    }

    private func groupIdentifier(for day: TrainingDayFS, offset: Int) -> String {
        if let date = day.date {
            let normalizedDate = Calendar.current.startOfDay(for: date)
            return "date-\(Int(normalizedDate.timeIntervalSinceReferenceDate))"
        }

        let dayID = day.id?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return dayID.isEmpty ? "undated-\(day.dayIndex)-\(offset)" : "undated-\(dayID)"
    }

    private func initializeExpandedDays(with days: [TrainingDayFS]) {
        guard !hasInitializedExpandedDays, !days.isEmpty else { return }
        hasInitializedExpandedDays = true

        if isTeacherViewing, initialExpandedDayId == nil {
            expandedDayIds = Set(trainingDayGroups.map(\.id))
            return
        }

        guard let initialExpandedDayId
        else {
            return
        }

        guard let group = trainingDayGroups.first(where: {
            $0.items.contains { $0.day.id == initialExpandedDayId }
        }) else {
            return
        }

        expandedDayIds = [group.id]
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // ✅ Overlay de conclusão da semana (mais rápido)
    private var weekCompletedOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                Text("Semana concluída!")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                Text("Parabéns! Você finalizou todos os registros da semana.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.green.opacity(0.9))
                    .padding(.top, 4)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .frame(maxWidth: 320)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.Colors.divider, lineWidth: 1)
            )
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: showWeekCompletedAnimation)
    }

    private func triggerWeekCompletedAnimation() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            showWeekCompletedAnimation = true
        }

        // ✅ Mais rápido
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.18)) {
                showWeekCompletedAnimation = false
            }
        }
    }
}
