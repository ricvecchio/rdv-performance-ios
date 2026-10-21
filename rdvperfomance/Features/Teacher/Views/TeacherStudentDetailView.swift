import SwiftUI

// TeacherStudentDetailView — Detalhes do aluno para o professor
struct TeacherStudentDetailView: View {

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

    @StateObject private var studentsViewModel: TeacherStudentsListViewModel

    private let contentMaxWidth: CGFloat = 380

    @State private var progress: Double = 0.0
    @State private var isLoadingProgress: Bool = false
    @State private var showUnlinkConfirm: Bool = false

    init(
        path: Binding<[AppRoute]>,
        student: AppUser,
        category: TreinoTipo,
        repository: FirestoreRepository = .shared
    ) {
        self._path = path
        self.student = student
        self.category = category
        _studentsViewModel = StateObject(
            wrappedValue: TeacherStudentsListViewModel(repository: repository)
        )
    }

    var body: some View {
        ZStack {

            AppThemeBackgroundImage()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(spacing: 14) {

                            headerCard()
                            actionsCard()

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
                Text("common.student")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundStyle(Theme.Colors.ink())
            }

            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appThemeLightHeaderColorScheme()
        .task {
            await loadProgress()
        }
        .alert("ui.unlink_student", isPresented: $showUnlinkConfirm) {
            Button("common.cancel", role: .cancel) {}
            Button("ui.unlink", role: .destructive) {
                Task { await confirmUnlink() }
            }
        } message: {
            let format = AppLocalization.string(
                "ui.student_will_be_unlinked_from_category",
                locale: locale
            )
            Text(String(format: format, locale: locale, arguments: [student.name, category.localizedDisplayName(locale: locale)]))
        }
    }

    // MARK: - Cards

    private func headerCard() -> some View {
        let percent = Int((progress * 100.0).rounded())

        return VStack(alignment: .leading, spacing: 10) {

            Text("common.student")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.Colors.ink(0.55))

            Text(student.name)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.95), light: LightColors.primaryText))

            Divider()
                .background(Theme.Colors.divider)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("ui.student_progress")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.ink(0.55))

                    Spacer()

                    if isLoadingProgress {
                        ProgressView().tint(Theme.Colors.ink())
                    }
                }

                Text(
                    String(
                        format: AppLocalization.string(
                            "ui.progress_complete_percentage",
                            locale: locale
                        ),
                        locale: locale,
                        arguments: [percent]
                    )
                )
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))

                ProgressView(value: progress)
                    .tint(.green.opacity(0.85))
            }

            Divider()
                .background(Theme.Colors.divider)

            Text("ui.workout_category")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.Colors.ink(0.55))

            Text(category.localizedDisplayName(locale: locale))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.Colors.systemAccentForeground(0.85))
        }
        .padding(16)
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

    private func actionsCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("ui.actions")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.Colors.ink(0.55))

            actionButton(title: AppLocalization.string("ui.workouts", locale: locale), icon: "calendar") {
                openWorkouts()
            }

            Divider()
                .background(Theme.Colors.divider)

            actionButton(title: AppLocalization.string("ui.messages", locale: locale), icon: "paperplane.fill") {
                path.append(.teacherMessage(student: student, category: category))
            }

            Divider()
                .background(Theme.Colors.divider)

            actionButton(title: AppLocalization.string("ui.feedbacks", locale: locale), icon: "text.bubble.fill") {
                path.append(.teacherFeedbacks(student: student, category: category))
            }

            Divider()
                .background(Theme.Colors.divider)

            actionButton(title: AppLocalization.string("ui.progress_preview", locale: locale), icon: "gamecontroller.fill") {
                path.append(.spriteDemo)
            }

            Divider()
                .background(Theme.Colors.divider)

            actionButton(title: AppLocalization.string("ui.unlink", locale: locale), icon: "person.badge.minus") {
                showUnlinkConfirm = true
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
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

    // MARK: - Helpers

    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(AppThemeColor(dark: Theme.Colors.systemAccentForeground(0.85).dark, light: LightColors.iconInk))
                    .frame(width: 22, alignment: .center)
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.35), light: LightColors.chevron))
            }
            .padding(14)
            .background(
                ZStack {
                    AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface)
                    AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.05), light: .clear)
                }
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.chevron), lineWidth: 1)
            )
            // Profundidade somente no Tema Claro (referência: AdminProfileSelectionView); Tema Escuro sem sombra
            .shadow(
                color: appTheme == .light ? .black.opacity(0.25) : .clear,
                radius: appTheme == .light ? 10 : 0,
                y: appTheme == .light ? 6 : 0
            )
        }
        .buttonStyle(.plain)
    }

    private func openWorkouts() {
        guard let sid = student.id, !sid.isEmpty else { return }
        path.append(.studentWorkouts(studentId: sid, studentName: student.name))
    }

    private func confirmUnlink() async {
        guard let teacherId = session.uid, !teacherId.isEmpty,
              let studentId = student.id, !studentId.isEmpty
        else {
            return
        }

        if await studentsViewModel.unlinkStudent(
            teacherId: teacherId,
            studentId: studentId,
            categoryToRemove: nil
        ) {
            pop()
        }
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // Carrega progresso geral do aluno
    private func loadProgress() async {
        guard session.isTrainer else { return }
        guard let sid = student.id, !sid.isEmpty else { return }

        isLoadingProgress = true
        defer { isLoadingProgress = false }

        do {
            let p = try await FirestoreRepository.shared.getStudentOverallProgress(studentId: sid)
            self.progress = Double(p.percent) / 100.0
        } catch {
            self.progress = 0.0
        }
    }
}
