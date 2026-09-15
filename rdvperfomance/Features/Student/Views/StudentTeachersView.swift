import SwiftUI
import FirebaseFirestore

struct StudentTeachersView: View {

    @Binding var path: [AppRoute]
    let studentEmail: String
    let onSelectSection: (StudentMainSection) -> Void

    @EnvironmentObject private var session: AppSession

    private let contentMaxWidth: CGFloat = 380
    private let repository: FirestoreRepository

    @State private var linkedTeachers: [AppUser] = []
    @State private var linkedTeacherIds: Set<String> = []
    @State private var sentRequests: [TeacherStudentLinkRequestFS] = []
    @State private var receivedInvites: [TeacherStudentInviteFS] = []
    @State private var inviteTeachers: [String: AppUser] = [:]
    @State private var isLoadingLinkedTeachers: Bool = false
    @State private var isLoadingData: Bool = false
    @State private var requestPendingCancellation: TeacherStudentLinkRequestFS? = nil
    @State private var invitePendingDecline: TeacherStudentInviteFS? = nil
    @State private var showRequestCancellationConfirmation: Bool = false
    @State private var showInviteDeclineConfirmation: Bool = false
    @State private var actionErrorMessage: String? = nil

    @State private var teacherEmailInput: String = ""
    @State private var linkActionMessage: String? = nil
    @State private var linkActionMessageIsError: Bool = false
    @State private var isProcessingLinkAction: Bool = false
    @State private var showRequestLinkModal: Bool = false
    @State private var resolvedStudentEmail: String = ""

    init(
        path: Binding<[AppRoute]>,
        studentEmail: String,
        onSelectSection: @escaping (StudentMainSection) -> Void,
        repository: FirestoreRepository = .shared
    ) {
        self._path = path
        self.studentEmail = studentEmail
        self.onSelectSection = onSelectSection
        self.repository = repository
        _resolvedStudentEmail = State(
            initialValue: studentEmail
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
        )
    }

    private var currentUid: String {
        (session.currentUid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedRouteStudentEmail: String {
        studentEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var effectiveStudentEmail: String {
        normalizedRouteStudentEmail.isEmpty ? resolvedStudentEmail : normalizedRouteStudentEmail
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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Gerencie seus professores e vínculos.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.55))

                            Button {
                                teacherEmailInput = ""
                                linkActionMessage = nil
                                linkActionMessageIsError = false
                                showRequestLinkModal = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.green.opacity(0.9))

                                    Text("Convidar professor")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.92))

                                    Spacer(minLength: 0)

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.35))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.green.opacity(0.16))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isProcessingLinkAction)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        linkedTeachersCard
                        sentRequestsCard
                        receivedInvitesCard
                    }
                    .frame(maxWidth: contentMaxWidth)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                    .frame(maxWidth: .infinity)
                }

                FooterBar(
                    path: $path,
                    kind: .studentHomeTreinosRecordsProfile(
                        isHomeSelected: false,
                        isTreinosSelected: false,
                        isRecordsSelected: false,
                        isPerfilSelected: true
                    ),
                    onSelectStudentSection: onSelectSection
                )
                .frame(height: Theme.Layout.footerHeight)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.footerBackground)
            }

            if showRequestLinkModal {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .blur(radius: showRequestLinkModal ? 8 : 0)
        .animation(.easeInOut(duration: 0.20), value: showRequestLinkModal)
        .ignoresSafeArea(.container, edges: [.bottom])
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    path.removeLast()
                } label: {
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
                Text("Meus professores")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showRequestLinkModal) {
            requestLinkModalView()
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.visible)
        }
        .task(id: "\(currentUid)|\(normalizedRouteStudentEmail)") {
            await loadStudentEmailIfNeeded()
            await refreshData()
        }
        .alert("Cancelar convite?", isPresented: $showRequestCancellationConfirmation) {
            Button("Cancelar", role: .cancel) { requestPendingCancellation = nil }
            Button("Confirmar cancelamento", role: .destructive) {
                Task { await cancelRequest() }
            }
        } message: {
            Text("Deseja cancelar este convite enviado ao professor?")
        }
        .alert("Recusar convite?", isPresented: $showInviteDeclineConfirmation) {
            Button("Cancelar", role: .cancel) { invitePendingDecline = nil }
            Button("Recusar", role: .destructive) {
                Task { await declineInvite() }
            }
        } message: {
            Text("Deseja recusar este convite de vínculo?")
        }
        .alert("Erro", isPresented: Binding(
            get: { actionErrorMessage != nil },
            set: { if !$0 { actionErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(actionErrorMessage ?? "Ocorreu um erro.")
        }
    }

    private var linkedTeachersCard: some View {
        card(title: "PROFESSORES VINCULADOS") {
            if isLoadingData {
                loadingView("Carregando professores...")
            } else if linkedTeachers.isEmpty {
                emptyView(
                    title: "Nenhum professor vinculado",
                    message: "Convide ou aceite um professor para aparecer aqui."
                )
            } else {
                ForEach(linkedTeachers, id: \.id) { teacher in
                    teacherRow(teacher)
                    if teacher.id != linkedTeachers.last?.id {
                        cardDivider
                    }
                }
            }
        }
    }

    private var sentRequestsCard: some View {
        card(title: "CONVITES ENVIADOS") {
            if isLoadingData {
                loadingView("Carregando convites...")
            } else if sentRequests.isEmpty {
                emptyView(title: "Nenhum convite enviado", message: "Convide um professor para iniciar um vínculo.")
            } else {
                ForEach(sentRequests, id: \.id) { request in
                    sentRequestRow(request)
                    if request.id != sentRequests.last?.id {
                        cardDivider
                    }
                }
            }
        }
    }

    private var receivedInvitesCard: some View {
        card(title: "CONVITES RECEBIDOS") {
            if isLoadingData {
                loadingView("Carregando convites...")
            } else if receivedInvites.isEmpty {
                emptyView(title: "Nenhum convite pendente", message: "Convites de professores aparecerão aqui.")
            } else {
                ForEach(receivedInvites, id: \.id) { invite in
                    receivedInviteRow(invite)
                    if invite.id != receivedInvites.last?.id {
                        cardDivider
                    }
                }
            }
        }
    }

    private func card<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.35))
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, alignment: .leading)

            content()
            Color.clear.frame(height: 8)
        }
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private func teacherRow(_ teacher: AppUser) -> some View {
        HStack(spacing: 14) {
            StudentAvatarView(base64: teacher.photoBase64, size: 28)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(teacher.name)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(teacher.email)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.35))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
    }

    private func sentRequestRow(_ request: TeacherStudentLinkRequestFS) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .foregroundColor(.yellow.opacity(0.75))
                .font(.system(size: 15))
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 3) {
                Text(request.teacherEmail)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)
                    .truncationMode(.tail)
                pendingStatus
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            Menu {
                Button(role: .destructive) {
                    requestPendingCancellation = request
                    showRequestCancellationConfirmation = true
                } label: {
                    Label("Cancelar convite", systemImage: "xmark.circle")
                }
            } label: {
                menuIcon
            }
            .buttonStyle(.plain)
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }

    private func receivedInviteRow(_ invite: TeacherStudentInviteFS) -> some View {
        let teacher = inviteTeachers[invite.teacherId]

        return HStack(spacing: 14) {
            StudentAvatarView(base64: teacher?.photoBase64, size: 28)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(teacher?.name ?? invite.teacherEmail)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(invite.teacherEmail)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.35))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            Menu {
                Button {
                    Task { await acceptInvite(invite) }
                } label: {
                    Label("Aceitar vínculo", systemImage: "checkmark")
                }
                Button(role: .destructive) {
                    invitePendingDecline = invite
                    showInviteDeclineConfirmation = true
                } label: {
                    Label("Recusar convite", systemImage: "xmark.circle")
                }
            } label: {
                menuIcon
            }
            .buttonStyle(.plain)
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
    }

    private var pendingStatus: some View {
        Text("Pendente")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.yellow.opacity(0.85))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.yellow.opacity(0.12)))
    }

    private var menuIcon: some View {
        Image(systemName: "ellipsis")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white.opacity(0.55))
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
    }

    private var cardDivider: some View {
        Divider()
            .background(Theme.Colors.divider)
            .padding(.horizontal, 16)
    }

    private func loadingView(_ text: String) -> some View {
        VStack(spacing: 10) {
            ProgressView()
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private func emptyView(title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 10)
    }

    private func requestLinkModalView() -> some View {
        NavigationStack {
            ZStack {
                Theme.Colors.headerBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 14) {
                    Text("Digite o e-mail do professor para enviar a solicitação.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.55))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("E-mail do professor")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))

                        TextField("professor@email.com", text: $teacherEmailInput)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled(true)
                            .padding(12)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                            .foregroundColor(.white.opacity(0.92))
                    }

                    if let message = linkActionMessage {
                        Text(message)
                            .font(.system(size: 13))
                            .foregroundColor(linkActionMessageIsError ? .yellow.opacity(0.95) : .green.opacity(0.95))
                    }

                    HStack(spacing: 10) {
                        Button {
                            showRequestLinkModal = false
                        } label: {
                            Text("Voltar")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.75))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(Color.white.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                        .disabled(isProcessingLinkAction)

                        Button {
                            Task {
                                let didSend = await requestLinkByTeacherEmail(teacherEmail: teacherEmailInput)
                                if didSend {
                                    showRequestLinkModal = false
                                }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Text("Enviar solicitação")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.92))

                                if isProcessingLinkAction {
                                    ProgressView()
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.green.opacity(0.20)))
                        }
                        .buttonStyle(.plain)
                        .disabled(isProcessingLinkAction)
                    }

                    Spacer(minLength: 0)
                }
                .padding(16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Convidar professor")
                        .font(Theme.Fonts.headerTitle())
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") {
                        showRequestLinkModal = false
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func loadStudentEmailIfNeeded() async {
        guard normalizedRouteStudentEmail.isEmpty else {
            resolvedStudentEmail = normalizedRouteStudentEmail
            return
        }

        let uid = currentUid
        guard !uid.isEmpty else {
            resolvedStudentEmail = ""
            return
        }

        do {
            let user = try await repository.getUser(uid: uid)
            resolvedStudentEmail = user?.email
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() ?? ""
        } catch {
            resolvedStudentEmail = ""
        }
    }

    private func loadLinkedTeachers(forceFallbackFromWeeks: Bool) async {
        let uid = currentUid
        guard !uid.isEmpty else {
            linkedTeachers = []
            linkedTeacherIds = []
            return
        }

        isLoadingLinkedTeachers = true
        defer { isLoadingLinkedTeachers = false }

        var teacherIds: [String] = []

        do {
            let relations = try await repository.getTeacherLinksForStudent(studentId: uid)
            teacherIds = Array(
                Set(
                    relations
                        .map { $0.teacherId.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                )
            )
        } catch {
            teacherIds = []
        }

        if teacherIds.isEmpty, forceFallbackFromWeeks {
            do {
                let weeks = try await repository.getWeeksForStudent(studentId: uid, onlyPublished: false)
                teacherIds = Array(
                    Set(
                        weeks
                            .map { $0.teacherId.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                    )
                )
            } catch {
                teacherIds = []
            }
        }

        linkedTeacherIds = Set(teacherIds)

        guard !teacherIds.isEmpty else {
            linkedTeachers = []
            return
        }

        let repo = repository
        var result: [AppUser] = []

        await withTaskGroup(of: AppUser?.self) { group in
            for teacherId in teacherIds {
                group.addTask {
                    do {
                        return try await repo.getUser(uid: teacherId)
                    } catch {
                        return nil
                    }
                }
            }

            for await user in group {
                if let user {
                    result.append(user)
                }
            }
        }

        result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        linkedTeachers = result
    }

    private func refreshData() async {
        let uid = currentUid
        guard !uid.isEmpty else {
            linkedTeachers = []
            linkedTeacherIds = []
            sentRequests = []
            receivedInvites = []
            inviteTeachers = [:]
            return
        }

        isLoadingData = true
        defer { isLoadingData = false }
        await loadLinkedTeachers(forceFallbackFromWeeks: true)

        do {
            async let requests = repository.getRequestsForStudent(studentId: uid)
            let allInvites: [TeacherStudentInviteFS]
            if effectiveStudentEmail.isEmpty {
                allInvites = []
            } else {
                allInvites = try await repository.getInvitesForStudent(studentEmail: effectiveStudentEmail)
            }
            let allRequests = try await requests

            sentRequests = allRequests.filter {
                let teacherId = $0.teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
                let status = $0.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                return status == "pending" && !linkedTeacherIds.contains(teacherId)
            }
            receivedInvites = allInvites.filter {
                let teacherId = $0.teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
                let status = $0.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                return status == "pending" && !linkedTeacherIds.contains(teacherId)
            }

            let teacherIds = Array(
                Set(
                    receivedInvites
                        .map { $0.teacherId.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                )
            )
            inviteTeachers = try await repository.getUsers(byIds: teacherIds)
        } catch {
            sentRequests = []
            receivedInvites = []
            inviteTeachers = [:]
            actionErrorMessage = (error as NSError).localizedDescription
        }
    }

    private func cancelRequest() async {
        guard let request = requestPendingCancellation,
              let requestId = request.id?.trimmingCharacters(in: .whitespacesAndNewlines),
              !requestId.isEmpty else {
            requestPendingCancellation = nil
            actionErrorMessage = "Não foi possível identificar o convite."
            return
        }

        do {
            try await repository.cancelLinkRequest(requestId: requestId)
            requestPendingCancellation = nil
            await refreshData()
        } catch {
            requestPendingCancellation = nil
            actionErrorMessage = (error as NSError).localizedDescription
        }
    }

    private func acceptInvite(_ invite: TeacherStudentInviteFS) async {
        let uid = currentUid
        guard !uid.isEmpty else {
            actionErrorMessage = "Não foi possível identificar o aluno."
            return
        }

        do {
            try await repository.acceptInvite(invite: invite, studentId: uid)
            await refreshData()
        } catch {
            actionErrorMessage = (error as NSError).localizedDescription
        }
    }

    private func declineInvite() async {
        guard let invite = invitePendingDecline else {
            return
        }

        do {
            try await repository.declineInvite(invite: invite)
            invitePendingDecline = nil
            await refreshData()
        } catch {
            invitePendingDecline = nil
            actionErrorMessage = (error as NSError).localizedDescription
        }
    }

    private func requestLinkByTeacherEmail(teacherEmail: String) async -> Bool {
        let email = teacherEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard email.contains("@"), email.contains(".") else {
            linkActionMessage = "Informe um e-mail válido."
            linkActionMessageIsError = true
            return false
        }

        let uid = currentUid
        guard !uid.isEmpty else {
            linkActionMessage = "Não foi possível identificar o aluno."
            linkActionMessageIsError = true
            return false
        }

        await loadStudentEmailIfNeeded()
        let currentStudentEmail = effectiveStudentEmail
        if currentStudentEmail.isEmpty {
            linkActionMessage = "Não foi possível identificar o e-mail do aluno."
            linkActionMessageIsError = true
            return false
        }

        isProcessingLinkAction = true
        linkActionMessage = nil
        linkActionMessageIsError = false
        defer { isProcessingLinkAction = false }

        do {
            guard let teacher = try await repository.getTeacherByEmail(email: email),
                  let teacherIdRaw = teacher.id else {
                linkActionMessage = "Não encontrei um professor com esse e-mail."
                linkActionMessageIsError = true
                return false
            }

            let teacherId = teacherIdRaw.trimmingCharacters(in: .whitespacesAndNewlines)
            if teacherId.isEmpty {
                linkActionMessage = "Não foi possível identificar o professor."
                linkActionMessageIsError = true
                return false
            }

            await loadLinkedTeachers(forceFallbackFromWeeks: true)

            if linkedTeacherIds.contains(teacherId) {
                linkActionMessage = "Esse professor já está vinculado."
                linkActionMessageIsError = true
                return false
            }

            do {
                let requests = try await repository.getRequestsForStudent(studentId: uid)
                let hasPendingSameTeacher = requests.contains { request in
                    let requestTeacherId = request.teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
                    let status = request.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    return requestTeacherId == teacherId && status == "pending"
                }
                if hasPendingSameTeacher {
                    linkActionMessage = "Já existe uma solicitação pendente para esse professor."
                    linkActionMessageIsError = true
                    return false
                }
            } catch {
            }

            try await repository.createLinkRequest(
                studentId: uid,
                studentEmail: currentStudentEmail,
                teacherId: teacherId,
                teacherEmail: email
            )

            linkActionMessage = "Solicitação enviada com sucesso."
            linkActionMessageIsError = false

            await refreshData()
            return true
        } catch {
            let nsError = error as NSError
            if nsError.domain == FirestoreErrorDomain,
               nsError.code == FirestoreErrorCode.permissionDenied.rawValue {
                linkActionMessage = "Sem permissão para solicitar vínculo. Ajuste as regras do Firestore para permitir localizar professores."
                linkActionMessageIsError = true
                return false
            }

            linkActionMessage = nsError.localizedDescription
            linkActionMessageIsError = true
            return false
        }
    }
}
