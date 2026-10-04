import SwiftUI

struct StudentTeachersListView: View {

    @Binding var path: [AppRoute]
    let studentEmail: String

    @EnvironmentObject private var session: AppSession
    @Environment(\.locale) private var locale
    @StateObject private var vm = StudentTeachersListViewModel()
    @State private var showInviteSheet = false
    @State private var teacherEmail = ""
    @State private var inviteToDecline: TeacherStudentInviteFS?
    @State private var showDeclineConfirmation = false
    @State private var requestToCancel: TeacherStudentLinkRequestFS?
    @State private var showCancelConfirmation = false
    @State private var selectedTeacher: AppUser?
    @State private var inviteError: String?

    private let contentMaxWidth: CGFloat = 380

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
                    kind: .agendaSobrePerfil(
                        isAgendaSelected: false,
                        isSobreSelected: false,
                        isPerfilSelected: false
                    )
                )
                .frame(height: Theme.Layout.footerHeight)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .blur(radius: showInviteSheet ? 8 : 0)
        .animation(.easeInOut(duration: 0.18), value: showInviteSheet)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { pop() } label: {
                    ZStack {
                        Color.clear.frame(width: 44, height: 44)
                        Image(systemName: "chevron.left").foregroundColor(.green)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("common.trainers")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        teacherEmail = ""
                        inviteError = nil
                        showInviteSheet = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "paperplane.fill")
                            Text("student_teachers.invite")
                        }
                        .padding(.horizontal, 10)
                        .primaryGreenActionButton()
                    }
                    .buttonStyle(.plain)

                    HeaderAvatarView(size: 38)
                }
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task(id: session.uid ?? "") {
            await load()
        }
        .sheet(isPresented: $showInviteSheet) {
            inviteSheet
                .presentationDetents([.medium, .large])
                .presentationContentInteraction(.scrolls)
                .presentationDragIndicator(.hidden)
        }
        .alert("student_teachers.decline_invitation_confirmation_title", isPresented: $showDeclineConfirmation) {
            Button("common.cancel", role: .cancel) { inviteToDecline = nil }
            Button("student_teachers.decline", role: .destructive) {
                Task { await declineInvite() }
            }
        } message: {
            Text("student_teachers.do_you_want_to_decline_this_link_invitation")
        }
        .alert("student_teachers.cancel_invitation_confirmation_title", isPresented: $showCancelConfirmation) {
            Button("common.cancel", role: .cancel) { requestToCancel = nil }
            Button("student_teachers.confirm_cancellation", role: .destructive) {
                Task { await cancelRequest() }
            }
        } message: {
            Text("student_teachers.do_you_want_to_cancel_this_invitation_sent_to_the_coach")
        }
        .sheet(item: $selectedTeacher) { teacher in
            teacherDetail(teacher)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .alert("common.error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? AppLocalization.string("common.unexpected_error", locale: locale))
        }
    }

    private var header: some View {
        Text("student_teachers.manage_your_linked_coaches_and_invitations")
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.35))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var linkedTeachersCard: some View {
        card(title: "student_teachers.linked_coaches_section") {
            if vm.isLoading {
                loading("student_teachers.loading_teachers")
            } else if vm.linkedTeachers.isEmpty {
                empty("student_teachers.no_linked_coach")
            } else {
                ForEach(Array(vm.linkedTeachers.enumerated()), id: \.offset) { index, teacher in
                    teacherRow(teacher)
                    if index < vm.linkedTeachers.count - 1 {
                        divider()
                    }
                }
            }
        }
    }

    private var sentRequestsCard: some View {
        card(title: "student_teachers.sent_invitations_section") {
            if vm.isLoading {
                loading("student_teachers.loading_invitations")
            } else if vm.sentRequests.isEmpty {
                empty("student_teachers.no_sent_invitations_yet")
            } else {
                ForEach(Array(vm.sentRequests.enumerated()), id: \.offset) { index, request in
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.yellow.opacity(0.75))
                            .font(.system(size: 15))
                            .frame(width: 26)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(request.teacherEmail)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.92))
                            Text("student_teachers.pending")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.yellow.opacity(0.85))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.yellow.opacity(0.12)))
                        }
                        Spacer()
                        Menu {
                            Button(role: .destructive) {
                                requestToCancel = request
                                showCancelConfirmation = true
                            } label: {
                                Label(LocalizedStringKey("student_teachers.cancel_invitation_action"), systemImage: "xmark.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white.opacity(0.55))
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    if index < vm.sentRequests.count - 1 {
                        divider()
                    }
                }
            }
        }
    }

    private var receivedInvitesCard: some View {
        card(title: "student_teachers.received_invitations_section") {
            if vm.isLoading {
                loading("student_teachers.loading_invitations")
            } else if vm.receivedInvites.isEmpty {
                empty("student_teachers.no_pending_invitation")
            } else {
                ForEach(Array(vm.receivedInvites.enumerated()), id: \.offset) { index, invite in
                    inviteRow(invite)
                    if index < vm.receivedInvites.count - 1 {
                        divider()
                    }
                }
            }
        }
    }

    private func card<Content: View>(
        title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.35))
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)
            content()
            Color.clear.frame(height: 8)
        }
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private func teacherRow(_ teacher: AppUser) -> some View {
        Button {
            selectedTeacher = teacher
        } label: {
            HStack(spacing: 14) {
                StudentAvatarView(base64: teacher.photoBase64, size: 28)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(teacher.name)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.92))
                    Text(teacher.email)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.35))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func inviteRow(_ invite: TeacherStudentInviteFS) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "envelope.fill")
                .foregroundColor(.green.opacity(0.85))
                .font(.system(size: 16))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(invite.teacherEmail)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.92))
                Text("student_teachers.pending")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.yellow.opacity(0.85))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.yellow.opacity(0.12)))
            }
            Spacer()
            Menu {
                Button {
                    Task { await acceptInvite(invite) }
                } label: {
                    Label(LocalizedStringKey("student_teachers.accept_link"), systemImage: "checkmark")
                }
                Button(role: .destructive) {
                    inviteToDecline = invite
                    showDeclineConfirmation = true
                } label: {
                    Label(LocalizedStringKey("student_teachers.decline_invitation_action"), systemImage: "xmark.circle")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func loading(_ text: LocalizedStringKey) -> some View {
        HStack(spacing: 10) {
            ProgressView()
            Text(text).font(.system(size: 13)).foregroundColor(.white.opacity(0.55))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    private func empty(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(.white.opacity(0.55))
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
    }

    private func divider() -> some View {
        Divider().background(Theme.Colors.divider).padding(.leading, 54)
    }

    private var inviteSheet: some View {
        ZStack {
            Image("rdv_fundo").resizable().scaledToFill().ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    Capsule()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 48, height: 6)
                        .padding(.top, 10)

                    Text("dashboard.invite_coach")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("student_teachers.invite_by_email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.35))

                        Text("student_teachers.enter_the_coach_s_email_to_send_the_invitation")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.55))

                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.white.opacity(0.35))
                            TextField("dashboard.coach_email", text: $teacherEmail)
                                .foregroundColor(.white.opacity(0.92))
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )

                        if let inviteError {
                            Text(inviteError).font(.system(size: 13)).foregroundColor(.yellow.opacity(0.95))
                        }

                        Button {
                            Task { await sendInvite() }
                        } label: {
                            HStack(spacing: 10) {
                                Spacer()
                                Image(systemName: "paperplane.fill")
                                Text("student_teachers.send_invitation")
                                Spacer()
                            }
                            .primaryGreenActionButton()
                        }
                        .buttonStyle(.plain)
                        .disabled(teacherEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(14)
                    .padding(.horizontal, 16)

                    Spacer(minLength: 10)
                }
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func load() async {
        guard let studentId = session.uid, !studentId.isEmpty else {
            vm.errorMessage = AppLocalization.string("student_shared.logged_student_not_found",
                locale: locale
            )
            return
        }
        await vm.load(studentId: studentId, studentEmail: studentEmail)
    }

    private func sendInvite() async {
        guard let studentId = session.uid, !studentId.isEmpty else { return }
        inviteError = await vm.sendRequest(
            studentId: studentId,
            studentEmail: studentEmail,
            teacherEmail: teacherEmail,
            locale: locale
        )
        if inviteError == nil {
            showInviteSheet = false
        }
    }

    private func acceptInvite(_ invite: TeacherStudentInviteFS) async {
        guard let studentId = session.uid, !studentId.isEmpty else { return }
        await vm.accept(invite: invite, studentId: studentId, studentEmail: studentEmail)
    }

    private func declineInvite() async {
        guard let invite = inviteToDecline,
              let studentId = session.uid,
              !studentId.isEmpty else { return }
        await vm.decline(invite: invite, studentId: studentId, studentEmail: studentEmail)
        inviteToDecline = nil
    }

    private func cancelRequest() async {
        guard let request = requestToCancel,
              let studentId = session.uid,
              !studentId.isEmpty else { return }
        await vm.cancel(request: request, studentId: studentId, studentEmail: studentEmail, locale: locale)
        requestToCancel = nil
    }

    private func teacherDetail(_ teacher: AppUser) -> some View {
        ZStack {
            Theme.Colors.headerBackground.ignoresSafeArea()
            VStack(spacing: 14) {
                Text("common.trainer")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)

                StudentAvatarView(base64: teacher.photoBase64, size: 72)
                Text(teacher.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                VStack(alignment: .leading, spacing: 8) {
                    teacherDetailRow(
                        AppLocalization.string("student_teachers.whatsapp", locale: locale),
                        BrazilianPhoneFormatter.format(teacher.phone ?? "")
                    )
                    teacherDetailRow(AppLocalization.string("student_teachers.cref", locale: locale), teacher.cref ?? "")
                    teacherDetailRow(AppLocalization.string("student_teachers.biography", locale: locale), teacher.bio ?? "")
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(14)

                Button("common.close") { selectedTeacher = nil }
                    .padding(.horizontal, 14)
                    .primaryGreenActionButton()
                    .buttonStyle(.plain)
                Spacer()
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func teacherDetailRow(_ title: String, _ value: String) -> some View {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let format = AppLocalization.string("common.label_value", locale: locale)
            Text(String(format: format, locale: locale, arguments: [title, trimmed]))
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.65))
        }
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
