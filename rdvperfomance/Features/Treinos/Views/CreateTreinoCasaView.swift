import SwiftUI
import FirebaseAuth

// Tema Claro: contorno verde-escuro (#294A2F), mesmo tom do card "Acesso rápido" da TeacherDashboardView
private let createWorkoutDarkGreenBorder = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)

// Tema Claro (habilitado): cores do botão Sair da ProfileView com as mesmas medidas do `primaryGreenActionButton()`.
// Tema Escuro e estado desabilitado: mantém exatamente o `primaryGreenActionButton()` original.
private struct LightMilitaryActionButtonModifier: ViewModifier {
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
                        .stroke(createWorkoutDarkGreenBorder, lineWidth: 1)
                )
        } else {
            content.primaryGreenActionButton()
        }
    }
}

// Tema Claro (habilitado): mesma estrutura e medidas do `WorkoutTemplateAttachmentButton` (`compactPrimaryGreenActionButton()`),
// com as cores do botão Sair da ProfileView. Tema Escuro e carregando: usa exatamente o componente compartilhado original.
private struct LightThemeAttachmentButton: View {
    @Environment(\.appTheme) private var appTheme
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        if appTheme == .light && !isLoading {
            Button(action: action) {
                HStack(spacing: 10) {
                    Image(systemName: "paperclip")
                    Text("workouts.attach_from_my_workouts")
                }
                .padding(.horizontal, 12)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.vertical, 9)
                .background(AppThemePalette.lightBar.opacity(0.80))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(createWorkoutDarkGreenBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        } else {
            WorkoutTemplateAttachmentButton(isLoading: isLoading, action: action)
        }
    }
}

/// Tela para criar um Treino (Em Casa) — layout idêntico ao "Adicionar WOD"
struct CreateTreinoCasaView: View {
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
        static let pendingStatus = Color(red: 0xB7 / 255, green: 0x79 / 255, blue: 0x00 / 255) // #B77900 (status Pendente da TeacherStudentsListView)
    }

    @Binding var path: [AppRoute]
    let category: TreinoTipo
    let sectionKey: String
    let sectionTitle: String

    @EnvironmentObject private var session: AppSession

    @State private var title: String = ""
    @State private var description: String = ""

    @State private var blocks: [BlockDraft] = [
        BlockDraft(defaultBlock: .warmup),
        BlockDraft(defaultBlock: .technique),
        BlockDraft(defaultBlock: .workout),
        BlockDraft(defaultBlock: .loadsAndMovements)
    ]

    @State private var showPasswordDummy: Bool = false

    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    @State private var isSelectingTemplateAttachment: Bool = false

    private let contentMaxWidth: CGFloat = 380

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

                        VStack(alignment: .leading, spacing: 14) {

                            header

                            trainingCard
                            blocksCard
                            saveButtonCard

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
                    kind: .teacherHomeAlunosSobrePerfil(
                        selectedCategory: category,
                        isHomeSelected: false,
                        isAlunosSelected: false,
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
                Text("ui.add_workout")
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
        .onReceive(NotificationCenter.default.publisher(for: .workoutTemplateSelectedForAttachment)) { notification in
            guard isSelectingTemplateAttachment,
                  let template = notification.object as? WorkoutTemplateFS else {
                return
            }
            isSelectingTemplateAttachment = false
            applyTemplate(template)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            (
                Text("ui.create_a_new")
                + Text("ui.home_workout_type").foregroundStyle(Theme.Colors.systemAccentForeground(0.85))
                + Text("ui.for_this_section")
            )
            .foregroundStyle(Theme.Colors.ink(0.55))
                .font(.system(size: 14))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var trainingCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            UnderlineTextField(
                title: "ui.workout_title_2",
                text: $title,
                isSecure: false,
                showPassword: $showPasswordDummy,
                lineColor: Theme.Colors.divider,
                textColor: .white.opacity(0.92),
                placeholderColor: .white.opacity(0.55),
                inputBackground: Color.white.opacity(0.06),
                inputBorderColor: Theme.Colors.primaryGreen.opacity(0.28)
            )

            Divider().background(Theme.Colors.divider)

            VStack(alignment: .leading, spacing: 6) {
                Text("ui.description")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.ink(0.55))

                TextEditor(text: $description)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.ink(0.75))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 90)
                    .padding(10)
                    .background(Theme.Colors.ink(0.06))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppThemeColor(dark: Theme.Colors.cardBorder.dark, light: LightColors.chevron), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
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

    private var blocksCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                LightThemeAttachmentButton(isLoading: false) {
                    isSelectingTemplateAttachment = true
                    path.append(.teacherEmCasaLibrary(mode: .library, templateMode: .attach))
                }

                Spacer()
                Button {
                    blocks.append(BlockDraft(defaultBlock: .newBlock))
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(AppThemeColor(dark: Theme.Colors.accentForeground.dark, light: LightColors.iconInk))
                        .font(.system(size: 17))
                }
                .buttonStyle(.plain)
            }

            ForEach($blocks) { $b in
                VStack(alignment: .leading, spacing: 10) {

                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            TextField(
                                "ui.new_block",
                                text: Binding(
                                    get: { b.displayedName(locale: locale) },
                                    set: { b.setDisplayedName($0) }
                                )
                            )
                                .foregroundStyle(Theme.Colors.ink(0.92))
                                .font(.system(size: 17))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)

                            Rectangle()
                                .fill(Theme.Colors.divider)
                                .frame(height: 1)
                        }
                        .frame(maxWidth: .infinity)

                        Spacer()

                        Button {
                            if let idx = blocks.firstIndex(where: { $0.id == b.id }) {
                                blocks.remove(at: idx)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(appTheme == .light ? LightColors.pendingStatus : .yellow.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        TextEditor(text: $b.details)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.Colors.ink(0.75))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 70)
                            .padding(10)
                            .background(Theme.Colors.ink(0.06))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppThemeColor(dark: Theme.Colors.cardBorder.dark, light: LightColors.chevron), lineWidth: 1)
                            )
                    }

                    Divider().background(Theme.Colors.divider)
                }
                .padding(.vertical, 6)
            }

            if blocks.isEmpty {
                Text("ui.no_block_added")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.ink(0.55))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
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

    private var saveButtonCard: some View {
        Button {
            Task { await saveTemplate() }
        } label: {
            HStack {
                Spacer()
                if isSaving {
                    ProgressView().tint(Theme.Colors.ink())
                } else {
                    Text("ui.save_workout")
                }
                Spacer()
            }
            .modifier(LightMilitaryActionButtonModifier())
            .shadow(
                color: appTheme == .light ? .black.opacity(0.25) : .clear,
                radius: appTheme == .light ? 10 : 0,
                y: appTheme == .light ? 6 : 0
            )
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
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
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.chevron), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }

    private func applyTemplate(_ template: WorkoutTemplateFS) {
        let localizedTemplate = DefaultWorkoutLocalization.presentation(for: template, locale: locale)
        title = localizedTemplate.title
        description = localizedTemplate.description
        blocks = (localizedTemplate.blocks ?? []).map {
            BlockDraft(name: $0.name, details: $0.details)
        }
    }

    private func saveTemplate() async {
        errorMessage = nil
        successMessage = nil

        guard session.isTrainer else {
            errorMessage = AppLocalization.string("ui.only_coaches_can_add_workouts", locale: locale)
            return
        }

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            errorMessage = AppLocalization.string("ui.unable_to_identify_the_signed_in_trainer", locale: locale)
            return
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            errorMessage = AppLocalization.string("ui.enter_the_workout_title", locale: locale)
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let payloadBlocks: [BlockFS] = blocks
                .filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .map { BlockFS(id: $0.id, name: $0.name, details: $0.details) }

            _ = try await FirestoreRepository.shared.createWorkoutTemplate(
                teacherId: teacherId,
                categoryRaw: category.rawValue,
                sectionKey: sectionKey,
                title: cleanTitle,
                description: description,
                blocks: payloadBlocks
            )

            pop()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
