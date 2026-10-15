// TeacherFeedbacksView.swift — Tela para professor registrar e listar feedbacks de um aluno
import SwiftUI
import FirebaseAuth

struct TeacherFeedbacksView: View {

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

    @State private var isLoading: Bool = false
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil

    @State private var feedbacks: [StudentFeedbackFS] = []

    @State private var newFeedbackText: String = ""
    @State private var showPasswordDummy: Bool = false

    @FocusState private var isFeedbackFocused: Bool

    private let successMessageScrollID = "teacherFeedbackSuccess"

    private let contentMaxWidth: CGFloat = 380

    // Corpo com histórico de feedbacks e formulário para novo feedback
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
                                listCard

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
                Text("ui.feedbacks")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundStyle(Theme.Colors.ink())
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            ToolbarItemGroup(placement: .topBarTrailing) {

                Button {
                    Task { await loadFeedbacks() }
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
        .task { await loadFeedbacks() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            let format = AppLocalization.string("ui.student_value", locale: locale)
            Text(String(format: format, locale: locale, arguments: [student.name]))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink(0.70))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var listCard: some View {
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

            if feedbacks.isEmpty {
                Text("ui.no_feedback_recorded_yet")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.ink(0.55))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(feedbacks.enumerated()), id: \.offset) { idx, fb in
                        feedbackRow(fb)
                        if idx < feedbacks.count - 1 { innerDivider(leading: 16) }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }

    private func feedbackRow(_ fb: StudentFeedbackFS) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if let date = fb.createdAt {
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

                Text(fb.text)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.ink(0.75))
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

                Text("ui.feedback")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink(0.35))
            }

            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $newFeedbackText)
                    .focused($isFeedbackFocused)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(Theme.Colors.ink(0.92))
                    .frame(minHeight: 120)
                    .padding(10)
                    .background(Theme.Colors.ink(0.06))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                Theme.Colors.primaryGreen.opacity(0.28),
                                lineWidth: 1
                            )
                    )
            }

            Divider().background(Theme.Colors.divider)

            Button { Task { await saveFeedback() } } label: {
                HStack {
                    Spacer()
                    if isSaving {
                        ProgressView().tint(Theme.Colors.ink())
                    } else {
                        Text("common.save")
                    }
                    Spacer()
                }
                .primaryGreenActionButton()
            }
            .buttonStyle(.plain)
            .disabled(isSaving || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1)
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
                .stroke(AppThemeAdaptiveColor(isError ? Color.white.opacity(0.10) : Theme.Colors.primaryGreen.opacity(0.28)), lineWidth: 1)
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
            return AppLocalization.string("ui.no_permission_to_access_this_student_s_feedback_verify_that_you_are_signed_in_as_a_coach_and_that_the_firestore_rules_allow_users_alunoid_feedbacks",
                locale: locale
            )
        }
        return msg
    }

    // Actions: load and save feedbacks
    private func loadFeedbacks() async {
        errorMessage = nil
        successMessage = nil

        guard session.isLoggedIn && session.isTrainer else {
            errorMessage = AppLocalization.string("ui.only_coaches_can_access_feedback", locale: locale)
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
            let list = try await FirestoreRepository.shared.getStudentFeedbacks(
                teacherId: teacherId,
                studentId: sid,
                categoryRaw: category.rawValue,
                limit: 50
            )
            self.feedbacks = list
        } catch {
            self.errorMessage = friendlyFirestoreError(error)
        }
    }

    // Salva novo feedback no Firestore
    private func saveFeedback() async {
        errorMessage = nil
        successMessage = nil

        guard session.isLoggedIn && session.isTrainer else {
            errorMessage = AppLocalization.string("ui.only_coaches_can_save_feedback", locale: locale)
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

        let textTrim = newFeedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textTrim.isEmpty else {
            errorMessage = AppLocalization.string("ui.enter_feedback_before_saving", locale: locale)
            return
        }

        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await FirestoreRepository.shared.createStudentFeedback(
                teacherId: teacherId,
                studentId: sid,
                categoryRaw: category.rawValue,
                text: textTrim
            )

            newFeedbackText = ""
            // Fecha o teclado somente após a gravação bem-sucedida
            isFeedbackFocused = false
            await loadFeedbacks()

            // Define o sucesso após o recarregamento, que limpa os estados de status
            successMessage = AppLocalization.string("ui.feedback_saved_successfully", locale: locale)

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
