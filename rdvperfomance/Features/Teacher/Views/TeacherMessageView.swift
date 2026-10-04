// TeacherMessageView.swift — Tela de mensagens entre professor e aluno
import SwiftUI
import FirebaseAuth

struct TeacherMessageView: View {

    @Binding var path: [AppRoute]
    let student: AppUser
    let category: TreinoTipo

    @EnvironmentObject private var session: AppSession
    @Environment(\.locale) private var locale

    @State private var message: String = ""

    @State private var isLoading: Bool = false
    @State private var isSending: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil

    @State private var messages: [TeacherMessageFS] = []

    private let contentMaxWidth: CGFloat = 380

    // Corpo com histórico de mensagens e formulário para nova mensagem
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
                            formCard
                            messagesCard

                            if let err = errorMessage {
                                messageCard(text: err, isError: true)
                            }

                            if let ok = successMessage {
                                messageCard(text: ok, isError: false)
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
                    kind: .teacherHomeAlunoSobrePerfil(
                        selectedCategory: category,
                        isHomeSelected: false,
                        isAlunoSelected: true,
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
                Text("ui.messages")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            ToolbarItemGroup(placement: .topBarTrailing) {

                Button {
                    Task { await loadMessages() }
                } label: {
                    ZStack {
                        Color.clear
                            .frame(width: 44, height: 44)

                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.green)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await loadMessages() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(
                String(
                    format: AppLocalization.string("ui.student_value", locale: locale),
                    locale: locale,
                    arguments: [student.name]
                )
            )
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.70))

            Text("ui.send_guidance_notices_and_messages_to_the_student")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var messagesCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("ui.history")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))

                Spacer()

                if isLoading {
                    ProgressView().tint(.white)
                }
            }

            if messages.isEmpty {
                Text("ui.no_message_has_been_sent_yet")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { idx, msg in
                        messageRow(msg)
                        if idx < messages.count - 1 { innerDivider(leading: 16) }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func messageRow(_ msg: TeacherMessageFS) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if let date = msg.createdAt {
                VStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .foregroundColor(.green.opacity(0.85))
                        .font(.system(size: 14))

                    Text(formatDate(date))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                }
                .frame(width: 76)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.userName ?? AppLocalization.string("common.trainer", locale: locale))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                Text(msg.body)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 8) {
                Image(systemName: "text.bubble.fill")
                    .foregroundColor(.green.opacity(0.85))
                    .font(.system(size: 14))

                Text("ui.message")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))
            }

            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $message)
                    .scrollContentBackground(.hidden)
                    .foregroundColor(.white.opacity(0.92))
                    .frame(minHeight: 140)
                    .padding(10)
                    .background(Color.black.opacity(0.25))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            }

            Divider().background(Theme.Colors.divider)

            Button { Task { await sendMessage() } } label: {
                HStack {
                    Spacer()
                    if isSending {
                        ProgressView().tint(.white)
                    } else {
                        Text("ui.send")
                    }
                    Spacer()
                }
                .primaryGreenActionButton()
            }
            .buttonStyle(.plain)
            .disabled(isSending || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func messageCard(text: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .yellow.opacity(0.85) : .green.opacity(0.85))
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.75))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.35))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func innerDivider(leading: CGFloat) -> some View {
        Divider()
            .background(Theme.Colors.divider)
            .padding(.leading, leading)
    }

    private func friendlyFirestoreError(_ error: Error) -> String {
        let msg = (error as NSError).localizedDescription
        if msg.lowercased().contains("missing or insufficient permissions") {
            return String(
                localized: "ui.you_do_not_have_permission_to_access_this_students_messages_confirm_that_you_are_signed_in_as_a_trainer_and_that_firestore_rules_allow_users_alunoid_messages",
                locale: locale
            )
        }
        return msg
    }

    // Actions: load and send messages
    private func loadMessages() async {
        errorMessage = nil
        successMessage = nil

        guard session.isLoggedIn && session.isTrainer else {
            errorMessage = AppLocalization.string("ui.only_trainers_can_access_messages", locale: locale)
            return
        }

        guard let sid = student.id, !sid.isEmpty else {
            errorMessage = AppLocalization.string("ui.invalid_student_id_not_found", locale: locale)
            return
        }

        guard let teacherId = Auth.auth().currentUser?.uid, !teacherId.isEmpty else {
            errorMessage = AppLocalization.string(
                "ui.unable_to_identify_the_signed_in_trainer",
                locale: locale
            )
            return
        }

        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let list = try await FirestoreRepository.shared.getTeacherMessages(
                teacherId: teacherId,
                studentId: sid,
                categoryRaw: category.rawValue,
                limit: 50
            )
            self.messages = list
        } catch {
            self.errorMessage = friendlyFirestoreError(error)
        }
    }

    // Envia nova mensagem para aluno
    private func sendMessage() async {
        errorMessage = nil
        successMessage = nil

        guard session.isLoggedIn && session.isTrainer else {
            errorMessage = AppLocalization.string("ui.only_trainers_can_send_messages", locale: locale)
            return
        }

        guard let sid = student.id, !sid.isEmpty else {
            errorMessage = AppLocalization.string("ui.invalid_student_id_not_found", locale: locale)
            return
        }

        guard let teacherId = Auth.auth().currentUser?.uid, !teacherId.isEmpty else {
            errorMessage = AppLocalization.string(
                "ui.unable_to_identify_the_signed_in_trainer",
                locale: locale
            )
            return
        }

        let bodyTrim = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !bodyTrim.isEmpty else {
            errorMessage = AppLocalization.string("ui.enter_a_message_before_sending", locale: locale)
            return
        }

        guard !isSending else { return }
        isSending = true
        defer { isSending = false }

        do {
            _ = try await FirestoreRepository.shared.createTeacherMessage(
                teacherId: teacherId,
                studentId: sid,
                categoryRaw: category.rawValue,
                subject: nil,
                body: bodyTrim
            )

            let local = TeacherMessageFS(
                id: nil,
                teacherId: teacherId,
                studentId: sid,
                categoryRaw: category.rawValue,
                subject: nil,
                body: bodyTrim,
                createdAt: Date(),
                updatedAt: Date()
            )
            messages.insert(local, at: 0)

            message = ""
            successMessage = AppLocalization.string("ui.message_sent_successfully", locale: locale)

            // ✅ Sincroniza com Firestore
            await loadMessages()

        } catch {
            errorMessage = friendlyFirestoreError(error)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.setLocalizedDateFormatFromTemplate("ddMMyyyyHHmm")
        return f.string(from: date)
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
