import SwiftUI
import FirebaseAuth

struct TeacherWorkoutTemplatesListView: View {
    @Environment(\.locale) private var locale

    @Binding var path: [AppRoute]
    let category: TreinoTipo
    let sectionKey: String
    let sectionTitle: String

    private let contentMaxWidth: CGFloat = 380
    private let repo: FirestoreRepository = .shared

    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var items: [WorkoutTemplateFS] = []

    @State private var showCreateDialog: Bool = false
    @State private var newTitle: String = ""
    @State private var newDesc: String = ""

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
                    VStack(alignment: .leading, spacing: 14) {

                        header

                        contentCard

                        Color.clear.frame(height: Theme.Layout.footerHeight + 20)
                    }
                    .frame(maxWidth: contentMaxWidth)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                FooterBar(
                    path: $path,
                    kind: .teacherHomeAlunosSobrePerfil(
                        selectedCategory: category,
                        isHomeSelected: false,
                        isAlunosSelected: false,
                        isSobreSelected: false,
                        isPerfilSelected: false
                    )
                )
                .frame(height: Theme.Layout.footerHeight)
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
                Text(sectionTitle)
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newTitle = ""
                    newDesc = ""
                    showCreateDialog = true
                } label: {
                    ZStack {
                        Color.clear
                            .frame(width: 44, height: 44)

                        Image(systemName: "plus")
                            .foregroundColor(.green)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await load() }
        .alert("ui.new_workout", isPresented: $showCreateDialog) {
            TextField("ui.title", text: $newTitle)
            TextField("ui.description_optional", text: $newDesc)

            Button("common.cancel", role: .cancel) { }

            Button("common.save") {
                Task { await createTemplate() }
            }
        } message: {
            Text("ui.this_workout_will_be_available_in_my_workouts_to_attach_to_days_weeks")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            let format = AppLocalization.string("ui.category_value", locale: locale)
            Text(String(format: format, locale: locale, arguments: [category.localizedDisplayName(locale: locale)]))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.green.opacity(0.85))

            Text(
                String(
                    format: AppLocalization.string("ui.section_value", locale: locale),
                    locale: locale,
                    arguments: [sectionTitle]
                )
            )
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var contentCard: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingView
            } else if let err = errorMessage {
                errorView(err)
            } else if items.isEmpty {
                emptyView
            } else {
                listView
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.68))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
        )
    }

    private var listView: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                let presentation = DefaultWorkoutLocalization.presentation(for: item, locale: locale)
                HStack(spacing: 12) {

                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.green.opacity(0.85))
                        .frame(width: 26)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(presentation.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white.opacity(0.92))

                        if !presentation.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(presentation.description)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.55))
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.35))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)

                if idx < items.count - 1 {
                    Divider().background(Theme.Colors.divider).padding(.leading, 54)
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("ui.loading_workouts")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 10) {
            Text("workout.oops_unable_to_load")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text(msg)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)

            Button {
                Task { await load() }
            } label: {
                Text("ui.try_again")
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
            Text("ui.no_workout_registered")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text("ui.tap_to_create_your_first_workout")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 10)
    }

    private func load() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            errorMessage = AppLocalization.string("ui.unable_to_identify_the_signed_in_trainer", locale: locale)
            items = []
            return
        }

        do {
            items = try await repo.getWorkoutTemplates(
                teacherId: teacherId,
                categoryRaw: category.rawValue,
                sectionKey: sectionKey
            )
        } catch {
            errorMessage = error.localizedDescription
            items = []
        }
    }

    private func createTemplate() async {
        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else { return }

        let titleTrim = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !titleTrim.isEmpty else { return }

        do {
            _ = try await repo.createWorkoutTemplate(
                teacherId: teacherId,
                categoryRaw: category.rawValue,
                sectionKey: sectionKey,
                title: titleTrim,
                description: newDesc
            )
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
