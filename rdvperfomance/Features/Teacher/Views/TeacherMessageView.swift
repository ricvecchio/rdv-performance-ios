// TeacherMessageView.swift — Tela de mensagens entre professor e aluno
import SwiftUI
import FirebaseAuth

struct TeacherMessageView: View {

    @Binding var path: [AppRoute]
    let student: AppUser
    let category: TreinoTipo

    @EnvironmentObject private var session: AppSession
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

    @State private var message: String = ""

    @State private var isLoading: Bool = false
    @State private var isSending: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil

    @State private var messages: [TeacherMessageFS] = []

    @FocusState private var isMessageFocused: Bool

    private let successMessageScrollID = "teacherMessageSuccess"

    private let contentMaxWidth: CGFloat = 380

    // Corpo com histórico de mensagens e formulário para nova mensagem
    var body: some View {
        ZStack {

            AppThemeBackgroundImage()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                ScrollViewReader { proxy in
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
                                        .id(successMessageScrollID)
                                }

                                Color.clear.frame(height: Theme.Layout.footerHeight + 20)
                            }
                            .frame(maxWidth: contentMaxWidth)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)

                            Spacer(minLength: 0)
                        }
                    }
                    .onChange(of: successMessage) { _, newValue in
                        // Rola até a confirmação de sucesso para que fique visível
                        guard newValue != nil else { return }
                        withAnimation {
                            proxy.scrollTo(successMessageScrollID, anchor: .bottom)
                        }
                    }
                }

                FooterBar(
                    path: $path,
                    kind: .teacherHomeAlunosSobrePerfil(
                        selectedCategory: category,
                        isHomeSelected: false,
                        isAlunosSelected: true,
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
                            .foregroundStyle(Theme.Colors.systemAccentForeground())
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("ui.messages")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundStyle(Theme.Colors.ink())
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
                            .foregroundStyle(Theme.Colors.systemAccentForeground())
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appThemeLightHeaderColorScheme()
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
                .foregroundStyle(Theme.Colors.ink(0.70))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var messagesCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("ui.history")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink(0.35))

                Spacer()

                if isLoading {
                    ProgressView().tint(Theme.Colors.ink())
                }
            }

            if messages.isEmpty {
                Text("ui.no_message_has_been_sent_yet")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.ink(0.55))
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
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.innerSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.chevron), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }

    private func messageRow(_ msg: TeacherMessageFS) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if let date = msg.createdAt {
                VStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .foregroundStyle(AppThemeColor(dark: Theme.Colors.systemAccentForeground(0.85).dark, light: LightColors.iconInk))
                        .font(.system(size: 14))

                    Text(formatDate(date))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink(0.45))
                        .multilineTextAlignment(.center)
                }
                .frame(width: 76)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.userName ?? AppLocalization.string("common.trainer", locale: locale))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))

                Text(msg.body)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.ink(0.75))
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
                    .foregroundStyle(AppThemeColor(dark: Theme.Colors.systemAccentForeground(0.85).dark, light: LightColors.iconInk))
                    .font(.system(size: 14))

                Text("ui.message")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink(0.35))
            }

            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $message)
                    .focused($isMessageFocused)
                    .scrollContentBackground(.hidden)
                    // Tema Claro: paleta (#171C17 / #F0F7EF / #C9DFC9). Tema Escuro: valores originais.
                    .foregroundStyle(AppThemeColor(dark: Theme.Colors.ink(0.92).dark, light: LightColors.primaryText))
                    .frame(minHeight: 140)
                    .padding(10)
                    .background(AppThemeColor(dark: Theme.Colors.ink(0.06).dark, light: Theme.Colors.ink(0.10).light))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.chevron),
                                lineWidth: 1
                            )
                    )
            }

            Divider().background(Theme.Colors.divider)

            Button { Task { await sendMessage() } } label: {
                HStack {
                    Spacer()
                    if isSending {
                        ProgressView().tint(Theme.Colors.ink())
                    } else {
                        Text("ui.send")
                    }
                    Spacer()
                }
                // Tema Claro (habilitado): cores do botão Sair da ProfileView + profundidade da AdminProfileSelectionView.
                // Tema Escuro ou desabilitado: `primaryGreenActionButton()` original.
                .modifier(TeacherMessageLightBarActionButtonModifier())
            }
            .buttonStyle(.plain)
            .disabled(isSending || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.innerSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.chevron), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }

    private func messageCard(text: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .yellow.opacity(0.85) : .green.opacity(0.85))
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.ink(0.75))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    appTheme == .light
                        ? AnyShapeStyle(LightColors.chevron)
                        : AnyShapeStyle(AppThemeAdaptiveColor(isError ? Color.white.opacity(0.10) : Theme.Colors.primaryGreen.opacity(0.28))),
                    lineWidth: 1
                )
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
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
            return AppLocalization.string("ui.you_do_not_have_permission_to_access_this_students_messages_confirm_that_you_are_signed_in_as_a_trainer_and_that_firestore_rules_allow_users_alunoid_messages",
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
            // Fecha o teclado somente após a gravação bem-sucedida
            isMessageFocused = false

            // ✅ Sincroniza com Firestore
            await loadMessages()

            // Define o sucesso após o recarregamento, que limpa os estados de status
            successMessage = AppLocalization.string("ui.message_sent_successfully", locale: locale)

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

// Tema Claro: contorno verde-escuro (#294A2F), mesmo tom do card "Acesso rápido" da TeacherDashboardView
private let teacherMessageDarkGreenBorder = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)

// Tema Claro + habilitado: mesmas cores/transparências do botão Sair da ProfileView e sombra da
// AdminProfileSelectionView, preservando fonte, padding e arredondamento de `primaryGreenActionButton()`.
// Tema Escuro ou desabilitado: aplica exatamente o `primaryGreenActionButton()` original.
private struct TeacherMessageLightBarActionButtonModifier: ViewModifier {
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
                        .stroke(teacherMessageDarkGreenBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
        } else {
            content
                .primaryGreenActionButton()
        }
    }
}

