import SwiftUI

private struct CompactDestructiveAgendaActionButtonModifier: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(isEnabled ? .white.opacity(0.92) : .white.opacity(0.55))
            .padding(.vertical, 9)
            .background(isEnabled ? Color.red.opacity(0.20) : Color.white.opacity(0.10))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isEnabled ? Color.red.opacity(0.35) : Color.white.opacity(0.12),
                        lineWidth: 1
                    )
            )
    }
}

private extension View {
    func compactDestructiveAgendaActionButton() -> some View {
        modifier(CompactDestructiveAgendaActionButtonModifier())
    }
}

struct StudentDashboardView: View {
    @Binding var path: [AppRoute]
    let studentId: String
    let onSelectSection: (StudentMainSection) -> Void
    let onSelectWorkout: (String, String) -> Void

    @EnvironmentObject private var session: AppSession
    @StateObject private var viewModel: StudentDashboardViewModel
    @State private var isTeacherLinkIconPulsing = false
    @State private var isRequestLinkSheetPresented = false
    @State private var teacherEmailInput = ""
    @State private var isNextFitLoginSheetPresented = false
    @State private var nextFitEmailInput = ""
    @State private var nextFitPasswordInput = ""
    @State private var isNextFitLogoutConfirmationPresented = false
    @State private var isNextFitLogoutErrorPresented = false

    private let contentMaxWidth: CGFloat = 380

    init(
        path: Binding<[AppRoute]>,
        studentId: String,
        onSelectSection: @escaping (StudentMainSection) -> Void,
        onSelectWorkout: @escaping (String, String) -> Void = { _, _ in },
        repository: FirestoreRepository = .shared
    ) {
        self._path = path
        self.studentId = studentId
        self.onSelectSection = onSelectSection
        self.onSelectWorkout = onSelectWorkout
        _viewModel = StateObject(wrappedValue: StudentDashboardViewModel(studentId: studentId, repository: repository))
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
                            header
                            dashboardContent
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
                    kind: .studentHomeTreinosRecordsProfile(
                        isHomeSelected: true,
                        isTreinosSelected: false,
                        isRecordsSelected: false,
                        isPerfilSelected: false
                    ),
                    onSelectStudentSection: onSelectSection
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
                Text("Área do Aluno")
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
            Task { await viewModel.load() }
        }
        .sheet(isPresented: $isRequestLinkSheetPresented) {
            requestLinkSheet
                .presentationDetents([.fraction(0.50)])
        }
        .sheet(isPresented: $isNextFitLoginSheetPresented, onDismiss: clearNextFitCredentials) {
            nextFitLoginSheet
                .presentationDetents([.fraction(0.50)])
        }
        .alert("Não foi possível desconectar do NextFit.", isPresented: $isNextFitLogoutErrorPresented) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Tente novamente.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
            Text("Disciplina hoje, resultado amanhã! 💪")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var dashboardContent: some View {
        if !viewModel.pendingTeacherInvites.isEmpty {
            noticesCard
        }

        switch viewModel.teacherLinkState {
        case .loading:
            ProgressView()
                .tint(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
        case .unlinked:
            noLinkedTeacherCard
            if viewModel.isMuralhaStudent {
                nextFitWodCard
            }
        case .linked, .failed:
            progressCard
            if viewModel.isMuralhaStudent {
                nextFitWodCard
            } else {
                upcomingWorkoutsCard
            }
        }
    }

    private var noticesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow.opacity(0.85))
                Text("Avisos")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white.opacity(0.92))
            }

            Button {
                path.append(.studentTeachers(
                    studentEmail: viewModel.pendingTeacherInvites[0].studentEmail
                ))
            } label: {
                noticeRow(
                    icon: "person.crop.circle.badge.checkmark",
                    title: "Convite de professor",
                    message: inviteNoticeMessage
                )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var inviteNoticeMessage: String {
        let count = viewModel.pendingTeacherInvites.count
        return count == 1
            ? "Você possui um convite pendente"
            : "Você possui \(count) convites pendentes"
    }

    private func noticeRow(icon: String, title: String, message: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Theme.Colors.primaryGreen)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.92))
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.35))
        }
        .contentShape(Rectangle())
    }

    private var noLinkedTeacherCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 34, weight: .medium))
                .foregroundColor(Theme.Colors.primaryGreen)
                .scaleEffect(isTeacherLinkIconPulsing ? 1.06 : 0.94)
                .opacity(isTeacherLinkIconPulsing ? 1 : 0.75)
                .animation(
                    .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                    value: isTeacherLinkIconPulsing
                )

            Text("Você ainda não tem um professor vinculado")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white.opacity(0.92))

            Text("Vincule-se a um professor para receber treinos e acompanhar sua evolução.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))

            Button {
                teacherEmailInput = ""
                isRequestLinkSheetPresented = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "person.badge.plus")

                    Text("Convidar professor")
                }
                .padding(.horizontal, 14)
                .compactPrimaryGreenActionButton()
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .onAppear {
            isTeacherLinkIconPulsing = true
        }
    }

    private var requestLinkSheet: some View {
        ZStack {
            Theme.Colors.headerBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 44, height: 5)
                            .padding(.top, 10)

                        Text("Solicitar vínculo")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Digite o e-mail do professor para enviar a solicitação.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.45))

                            VStack(alignment: .leading, spacing: 8) {
                                Text("E-mail do professor")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.75))

                                TextField("professor@email.com", text: $teacherEmailInput)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled(true)
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.10))
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                    )
                                    .foregroundColor(.white.opacity(0.92))
                            }

                            if let msg = viewModel.linkActionMessage {
                                Text(msg)
                                    .font(.system(size: 13))
                                    .foregroundColor(viewModel.linkActionMessageIsError ? .yellow.opacity(0.95) : .green.opacity(0.95))
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        isRequestLinkSheetPresented = false
                    } label: {
                        Text("Cancelar")
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
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isProcessingLinkAction)

                    Button {
                        Task {
                            let ok = await viewModel.requestLinkByTeacherEmail(teacherEmail: teacherEmailInput)
                            if ok {
                                isRequestLinkSheetPresented = false
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Text("Enviar solicitação")

                            if viewModel.isProcessingLinkAction {
                                ProgressView()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .primaryGreenActionButton()
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isProcessingLinkAction)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
        }
    }

    private var progressCard: some View {
        let completed = viewModel.currentWeekDaySummaries.filter(\.isCompleted).count
        let total = viewModel.currentWeekDaySummaries.count
        let progress = total == 0 ? 0 : Double(completed) / Double(total)

        return VStack(alignment: .leading, spacing: 14) {
            Text("Progresso da semana")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white.opacity(0.92))
            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text("\(completed) de \(total) dias concluídos")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))
                HStack(spacing: 10) {
                    ProgressView(value: progress)
                        .tint(Theme.Colors.primaryGreen)
                    Text("\(Int((progress * 100).rounded()))%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                }
                if total == 0 {
                    Text("Você não possui treinos programados para esta semana.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.55))
                } else {
                    HStack(spacing: 10) {
                        ForEach(viewModel.currentWeekDaySummaries) { item in
                            VStack(spacing: 6) {
                                Image(systemName: item.isCompleted ? "checkmark.seal.fill" : "circle")
                                    .foregroundColor(item.isCompleted ? Theme.Colors.primaryGreen : .white.opacity(0.35))
                                Text(weekdayAbbreviation(for: item.date))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.75))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var nextFitWodCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(nextFitWodTitle)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white.opacity(0.92))

                Spacer()

                if viewModel.hasNextFitSession {
                    Button {
                        isNextFitLogoutConfirmationPresented = true
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.45))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isLoadingNextFitWod)
                    .accessibilityLabel("Desconectar NextFit")
                    .confirmationDialog(
                        "Desconectar NextFit?",
                        isPresented: $isNextFitLogoutConfirmationPresented,
                        titleVisibility: .visible
                    ) {
                        Button("Desconectar", role: .destructive) {
                            do {
                                try viewModel.logoutNextFit()
                            } catch {
                                isNextFitLogoutErrorPresented = true
                            }
                        }
                        Button("Cancelar", role: .cancel) { }
                    } message: {
                        Text("Você precisará entrar novamente para consultar o WOD do dia.")
                    }
                }
            }

            if viewModel.isLoadingNextFitWod {
                ProgressView()
                    .tint(.white)
            } else if viewModel.needsNextFitAuthentication {
                Text("Conecte sua conta NextFit para consultar o treino de hoje.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))

                Button {
                    nextFitEmailInput = ""
                    nextFitPasswordInput = ""
                    isNextFitLoginSheetPresented = true
                } label: {
                    ZStack(alignment: .leading) {
                        HStack(spacing: 10) {
                            Image(systemName: "person.badge.plus")

                            Text("Convidar professor")
                        }
                        .hidden()

                        HStack(spacing: 10) {
                            Image(systemName: "link")

                            Text("Conectar NextFit")
                        }
                    }
                    .padding(.horizontal, 14)
                    .compactPrimaryGreenActionButton()
                }
                .buttonStyle(.plain)
            } else if let error = viewModel.nextFitError {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))

                Button {
                    Task { await viewModel.retryNextFitWod() }
                } label: {
                    Text("Tentar novamente")
                        .padding(.horizontal, 14)
                        .compactPrimaryGreenActionButton()
                }
                .buttonStyle(.plain)
            } else {
                if viewModel.nextFitContentOptions.count > 1 {
                    Picker("", selection: $viewModel.selectedNextFitContent) {
                        ForEach(viewModel.nextFitContentOptions) { option in
                            Text(option.title.uppercased())
                                .tag(Optional(option.selection))
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(Color.white.opacity(0.06))
                }

                if viewModel.isNextFitAgendaSelected {
                    nextFitAgendaContent
                } else if let wod = viewModel.nextFitWod {
                    VStack(spacing: 10) {
                        ForEach(wod.activities) { activity in
                            VStack(alignment: .leading, spacing: 14) {
                                Text(activity.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Theme.Colors.primaryGreen)

                                Text(activity.description)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.92))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                    }
                } else {
                    Text("Nenhum WOD disponível para hoje.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    @ViewBuilder
    private var nextFitAgendaContent: some View {
        if viewModel.isLoadingNextFitAgendaDetail {
            ProgressView()
                .tint(.white)
        } else if let detail = viewModel.selectedNextFitAgendaDetail {
            nextFitAgendaDetailContent(detail)
        } else if let error = viewModel.nextFitAgendaDetailError {
            nextFitAgendaDetailErrorContent(error)
        } else if let error = viewModel.nextFitAgendaError {
            Text(error)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))

            Button {
                Task { await viewModel.retryNextFitWod() }
            } label: {
                Text("Tentar novamente")
                    .padding(.horizontal, 14)
                    .compactPrimaryGreenActionButton()
            }
            .buttonStyle(.plain)
        } else if viewModel.nextFitAgenda.isEmpty {
            Text("Nenhum horário disponível para hoje.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        } else {
            VStack(spacing: 10) {
                ForEach(viewModel.nextFitAgenda) { entry in
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            Task { await viewModel.selectNextFitAgenda(entry.id) }
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    nextFitAgendaDetailRow(
                                        icon: "clock",
                                        text: entry.scheduleText,
                                        font: .system(size: 14, weight: .medium),
                                        textColor: .white.opacity(0.92)
                                    )
                                    Spacer()
                                    nextFitAgendaDetailRow(
                                        icon: "person.2.fill",
                                        text: entry.capacityText,
                                        font: .system(size: 14, weight: .medium),
                                        textColor: .white.opacity(0.92)
                                    )
                                }
                                nextFitAgendaDetailRow(
                                    icon: "dumbbell.fill",
                                    text: entry.modalityName,
                                    font: .system(size: 16, weight: .semibold),
                                    textColor: Theme.Colors.primaryGreen
                                )
                                nextFitAgendaDetailRow(
                                    icon: "person.fill",
                                    text: entry.instructorName,
                                    textColor: .white.opacity(0.92)
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)

                        HStack {
                            nextFitAgendaDetailRow(
                                icon: "mappin.and.ellipse",
                                text: entry.locationName,
                                textColor: .white.opacity(0.55)
                            )
                            Spacer()
                            agendaCheckInButton(for: entry)
                        }
                        if let error = viewModel.agendaActionError(for: entry.id) {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(.red.opacity(0.9))
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
            }
        }
    }

    private func nextFitAgendaDetailContent(_ detail: NextFitAgendaDetailDisplay) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                viewModel.clearNextFitAgendaDetail()
            } label: {
                Label("Voltar à agenda", systemImage: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryGreen)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    nextFitAgendaDetailRow(icon: "calendar", text: detail.dateText)
                    Spacer()
                    nextFitAgendaDetailRow(icon: "person.2.fill", text: detail.capacityText)
                }
                nextFitAgendaDetailRow(icon: "clock", text: detail.scheduleText)
                nextFitAgendaDetailRow(icon: "dumbbell.fill", text: detail.modalityName)
                nextFitAgendaDetailRow(icon: "person.fill", text: detail.instructorName)
                nextFitAgendaDetailRow(icon: "mappin.and.ellipse", text: detail.locationName)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.06))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))

            Text("PARTICIPANTES")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.92))

            if detail.participants.isEmpty {
                Text("Nenhum participante neste horário.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))
            } else {
                ForEach(detail.participants) { participant in
                    Text(participant.name)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.92))
                }
            }

            if viewModel.canCancelAgendaCheckIn(detail.id) {
                HStack {
                    Spacer()
                    agendaCheckInButton(for: detail.id)
                }
            }

            if let error = viewModel.agendaActionError(for: detail.id) {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.red.opacity(0.9))
            }
        }
    }

    private func nextFitAgendaDetailErrorContent(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                viewModel.clearNextFitAgendaDetail()
            } label: {
                Label("Voltar à agenda", systemImage: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryGreen)
            }
            .buttonStyle(.plain)

            Text(error)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))

            Button {
                Task { await viewModel.retryNextFitAgendaDetail() }
            } label: {
                Text("Tentar novamente")
                    .padding(.horizontal, 14)
                    .compactPrimaryGreenActionButton()
            }
            .buttonStyle(.plain)
        }
    }

    private func nextFitAgendaDetailRow(
        icon: String,
        text: String,
        font: Font = .system(size: 14),
        textColor: Color = .white.opacity(0.92)
    ) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: icon)
                .foregroundColor(Theme.Colors.primaryGreen)
                .frame(width: 18)
        }
        .font(font)
        .foregroundColor(textColor)
    }

    @ViewBuilder
    private func agendaCheckInButton(for entry: NextFitAgendaDisplay) -> some View {
        if entry.endDate < Date() {
            Button { } label: {
                Text("Encerrado")
                    .padding(.horizontal, 14)
                    .compactPrimaryGreenActionButton()
            }
            .buttonStyle(.plain)
            .disabled(true)
        } else {
            agendaCheckInButton(for: entry.id)
        }
    }

    @ViewBuilder
    private func agendaCheckInButton(for agendaId: Int) -> some View {
        let isProcessing = viewModel.isProcessingAgenda(agendaId)
        if viewModel.canCancelAgendaCheckIn(agendaId) {
            Button {
                Task { await viewModel.cancelAgendaCheckIn(agendaId) }
            } label: {
                HStack(spacing: 10) {
                    if isProcessing {
                        ProgressView()
                    } else {
                        Image(systemName: "xmark.circle")
                    }
                    Text("Cancelar")
                }
                .padding(.horizontal, 14)
                .compactDestructiveAgendaActionButton()
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)
        } else {
            Button {
                Task { await viewModel.checkInAgenda(agendaId) }
            } label: {
                HStack(spacing: 10) {
                    if isProcessing {
                        ProgressView()
                    } else {
                        Image(systemName: "calendar.badge.plus")
                    }
                    Text("Agendar")
                }
                .padding(.horizontal, 14)
                .compactPrimaryGreenActionButton()
            }
            .buttonStyle(.plain)
            .disabled(isProcessing || !viewModel.canScheduleAgendaCheckIn(agendaId))
        }
    }

    private var nextFitWodTitle: String {
        let unitName = viewModel.studentUnitName
        return unitName.isEmpty ? "WOD do dia" : "WOD do dia (\(unitName))"
    }

    private var upcomingWorkoutsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Próximos treinos")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white.opacity(0.92))
                Spacer()
                Button("Ver todos") {
                    onSelectSection(.agenda)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.primaryGreen)
                .buttonStyle(.plain)
            }

            if viewModel.isLoading {
                ProgressView().tint(.white)
            } else if viewModel.upcomingDayGroups.isEmpty {
                Text("Nenhum treino programado.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))
            } else {
                ForEach(Array(viewModel.upcomingDayGroups.enumerated()), id: \.element.id) { index, item in
                    Button {
                        guard let dayId = item.initialDayId else { return }
                        onSelectWorkout(item.weekId, dayId)
                    } label: {
                        upcomingWorkoutRow(item)
                    }
                    .buttonStyle(.plain)
                    if index < viewModel.upcomingDayGroups.count - 1 {
                        Divider().background(Theme.Colors.divider).padding(.leading, 42)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var nextFitLoginSheet: some View {
        ZStack {
            Theme.Colors.headerBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 44, height: 5)
                            .padding(.top, 10)

                        Text("Entrar no NextFit")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("E-mail")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.75))

                                TextField("seu@email.com", text: $nextFitEmailInput)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled(true)
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.10))
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                    )
                                    .foregroundColor(.white.opacity(0.92))
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Senha")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.75))

                                SecureField("Sua senha", text: $nextFitPasswordInput)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.10))
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                    )
                                    .foregroundColor(.white.opacity(0.92))
                            }

                            if let error = viewModel.nextFitLoginError {
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundColor(.yellow.opacity(0.95))
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        isNextFitLoginSheetPresented = false
                    } label: {
                        Text("Cancelar")
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
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isAuthenticatingNextFit)

                    Button {
                        let email = nextFitEmailInput
                        let password = nextFitPasswordInput
                        nextFitPasswordInput = ""

                        Task {
                            if await viewModel.authenticateNextFit(email: email, password: password) {
                                isNextFitLoginSheetPresented = false
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Text("Entrar")

                            if viewModel.isAuthenticatingNextFit {
                                ProgressView()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .primaryGreenActionButton()
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isAuthenticatingNextFit)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
        }
    }

    private func clearNextFitCredentials() {
        nextFitEmailInput = ""
        nextFitPasswordInput = ""
    }

    private func upcomingWorkoutRow(_ item: StudentDashboardDayGroup) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "calendar")
                .font(.system(size: 18))
                .foregroundColor(.green.opacity(0.85))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(dateTitle(for: item.date))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.92))
                    Spacer()
                    Text("\(Int((item.progress * 100).rounded()))%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.primaryGreen)
                }
                Text("\(item.completedCount) de \(item.totalCount) \(item.totalCount == 1 ? "treino concluído" : "treinos concluídos")")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
                ProgressView(value: item.progress)
                    .tint(Theme.Colors.primaryGreen)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.35))
                .padding(.top, 3)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var greeting: String {
        let name = session.userName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Olá, Aluno!" : "Olá, \(name)!"
    }

    private func weekdayAbbreviation(for date: Date?) -> String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).replacingOccurrences(of: ".", with: "").capitalized
    }

    private func dateTitle(for date: Date?) -> String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE dd/MM"
        return formatter.string(from: date).capitalized(with: formatter.locale)
    }
}
