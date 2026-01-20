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

    @EnvironmentObject private var session: AppSession

    @AppStorage("ultimoTreinoSelecionado")
    private var ultimoTreinoSelecionado: String = TreinoTipo.crossfit.rawValue

    @StateObject private var vm: StudentWeekDetailViewModel
    private let contentMaxWidth: CGFloat = 380

    // ✅ Animação quando tudo estiver concluído
    @State private var showWeekCompletedAnimation: Bool = false
    @State private var hasTriggeredWeekCompletedAnimation: Bool = false

    init(
        path: Binding<[AppRoute]>,
        studentId: String,
        weekId: String,
        weekTitle: String,
        repository: FirestoreRepository = .shared
    ) {
        self._path = path
        self.studentId = studentId
        self.weekId = weekId
        self.weekTitle = weekTitle
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

    // ✅ Lista ordenada: vídeos primeiro, mantendo a ordem original dentro de cada grupo
    private var orderedDays: [(offset: Int, day: TrainingDayFS)] {
        let enumerated = Array(vm.days.enumerated()).map { (offset: $0.offset, day: $0.element) }
        return enumerated.sorted { a, b in
            let aIsVideo = isVideoDay(a.day)
            let bIsVideo = isVideoDay(b.day)
            if aIsVideo != bIsVideo { return aIsVideo && !bIsVideo }
            return a.offset < b.offset
        }
    }

    // ✅ Particiona em dois blocos REAIS: Vídeos e Treinos (como cards separados)
    private var videoDays: [(offset: Int, day: TrainingDayFS)] {
        orderedDays.filter { isVideoDay($0.day) }
    }

    private var trainingDays: [(offset: Int, day: TrainingDayFS)] {
        orderedDays.filter { !isVideoDay($0.day) }
    }

    private var hasAnyVideo: Bool { !videoDays.isEmpty }
    private var hasAnyNonVideo: Bool { !trainingDays.isEmpty }

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
        .toolbar {

            ToolbarItem(placement: .navigationBarLeading) {
                Button { pop() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("Semana")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            // Avatar no cabeçalho (foto real do usuário)
            ToolbarItem(placement: .navigationBarTrailing) {
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
                    kind: .agendaSobrePerfil(
                        isAgendaSelected: true,
                        isSobreSelected: false,
                        isPerfilSelected: false
                    )
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
                    HStack {
                        Image(systemName: "plus")
                        Text("Adicionar primeiro dia")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.green.opacity(0.16)))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // ✅ Conteúdo principal: mantém card para loading/erro/empty, e para lista usa DOIS CARDS (vídeos e treinos)
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
                // ✅ Aqui ficam DOIS BLOCOS (cards) como no seu StudentDayDetailView
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

    // ✅ DOIS CARDS separados (como Treino/Vídeos no StudentDayDetailView)
    private var daysCards: some View {
        VStack(spacing: 16) {

            if hasAnyVideo {
                daysSectionCard(
                    title: "Vídeos",
                    systemImage: "video.fill",
                    items: videoDays
                )
            }

            if hasAnyNonVideo {
                daysSectionCard(
                    title: "Treinos",
                    systemImage: "flame.fill",
                    items: trainingDays
                )
            }
        }
    }

    // ✅ Card de seção (mesmo padrão do seu StudentDayDetailView: background + cornerRadius)
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

                        Image(systemName: isVideo ? "video.fill" : "flame.fill")
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
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.green.opacity(0.16)))
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

