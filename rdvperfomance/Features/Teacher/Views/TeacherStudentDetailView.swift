import SwiftUI

// TeacherStudentDetailView — Detalhes do aluno para o professor
struct TeacherStudentDetailView: View {

    @Binding var path: [AppRoute]

    let student: AppUser
    let category: TreinoTipo

    @EnvironmentObject private var session: AppSession
    @Environment(\.locale) private var locale

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
                            .foregroundColor(.green)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("common.student")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
                .foregroundColor(.white.opacity(0.55))

            Text(student.name)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(0.95))

            Divider()
                .background(Theme.Colors.divider)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("ui.student_progress")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))

                    Spacer()

                    if isLoadingProgress {
                        ProgressView().tint(.white)
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
                    .foregroundColor(.white.opacity(0.92))

                ProgressView(value: progress)
                    .tint(.green.opacity(0.85))
            }

            Divider()
                .background(Theme.Colors.divider)

            Text("ui.workout_category")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.55))

            Text(category.localizedDisplayName(locale: locale))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.green.opacity(0.85))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.68))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
        )
    }

    private func actionsCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("ui.actions")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.55))

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
        .background(Color.black.opacity(0.68))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.green.opacity(0.85))
                    .frame(width: 22, alignment: .center)
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(14)
            .background(Color.white.opacity(0.06))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
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
