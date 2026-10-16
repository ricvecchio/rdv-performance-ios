import SwiftUI

struct TeacherMyWorkoutsView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo
    let mode: TeacherWorkoutsMode
    @Environment(\.locale) private var locale
    @Environment(\.appTheme) private var appTheme

    // Cores locais exclusivas do Tema Claro (padrao da TrainingWeeksView; Tema Escuro usa sempre os valores originais)
    private enum LightColors {
        static let cardSurface = Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)   // #DDEDDC
        static let iconSurface = Color(red: 0x85 / 255, green: 0xC9 / 255, blue: 0x95 / 255)   // #85C995
        static let iconInk = Color(red: 0x25 / 255, green: 0x48 / 255, blue: 0x2B / 255)       // #25482B
        static let primaryText = Color(red: 0x17 / 255, green: 0x1C / 255, blue: 0x17 / 255)   // #171C17
        static let chevron = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)       // #294A2F
        static let border = Color(red: 0xC9 / 255, green: 0xDF / 255, blue: 0xC9 / 255)        // #C9DFC9
    }

    private let contentMaxWidth: CGFloat = 410

    var body: some View {
        ZStack {

            AppThemeBackgroundImage()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                GeometryReader { proxy in
                    let tileHeight = max(180, (proxy.size.height - 60) / 3)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {

                            programaTile(
                                imageName: "rdv_programa_crossfit_horizontal",
                                height: tileHeight,
                                badgeText: "ui.crossfit_workouts",
                                badgeIcon: "figure.strengthtraining.traditional"
                            ) {
                                switch mode {
                                case .library:
                                    path.append(.teacherCrossfitLibrary(section: .benchmarks, mode: mode))
                                case .create:
                                    path.append(.createCrossfitWOD(
                                        category: .crossfit,
                                        sectionKey: "meusTreinos",
                                        sectionTitle: AppLocalization.string("ui.my_workouts", locale: locale)
                                    ))
                                }
                            }

                            programaTile(
                                imageName: "rdv_programa_academia_horizontal",
                                height: tileHeight,
                                badgeText: "ui.gym_workouts",
                                badgeIcon: "dumbbell"
                            ) {
                                switch mode {
                                case .library:
                                    path.append(.teacherAcademiaLibrary(mode: mode))
                                case .create:
                                    path.append(.createTreinoAcademia(
                                        category: .academia,
                                        sectionKey: "meusTreinos",
                                        sectionTitle: AppLocalization.string("ui.my_workouts", locale: locale)
                                    ))
                                }
                            }

                            programaTile(
                                imageName: "rdv_programa_treinos_em_casa_horizontal",
                                height: tileHeight,
                                badgeText: "ui.home_workouts",
                                badgeIcon: "house.fill"
                            ) {
                                switch mode {
                                case .library:
                                    path.append(.teacherEmCasaLibrary(mode: mode))
                                case .create:
                                    path.append(.createTreinoCasa(
                                        category: .emCasa,
                                        sectionKey: "meusTreinos",
                                        sectionTitle: AppLocalization.string("ui.my_workouts", locale: locale)
                                    ))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .frame(maxWidth: contentMaxWidth)
                        .frame(maxWidth: .infinity, alignment: .center)
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
                Text("ui.workout_library")
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
    }

    // MARK: - Tile

    private func programaTile(
        imageName: String,
        height: CGFloat,
        badgeText: LocalizedStringKey,
        badgeIcon: String,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {
            tileLayout(
                imageName: imageName,
                height: height,
                badgeText: badgeText,
                badgeIcon: badgeIcon
            )
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
        }
        .buttonStyle(.plain)
        .frame(height: height)
        .background(AppThemeColor(dark: Color.black.opacity(0.76), light: LightColors.cardSurface))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1)
        )
        // Tema Escuro: sombra original. Tema Claro: mesma profundidade da AdminProfileSelectionView (substitui, nao duplica)
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : Theme.Colors.primaryGreen.opacity(0.12),
            radius: appTheme == .light ? 10 : 6,
            y: appTheme == .light ? 6 : 2
        )
    }

    private func tileLayout(
        imageName: String,
        height: CGFloat,
        badgeText: LocalizedStringKey,
        badgeIcon: String
    ) -> some View {

        VStack(spacing: 0) {
            tileBase(imageName: imageName, height: height - 62)
            badgeView(text: badgeText, icon: badgeIcon)
        }
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
    }

    private func tileBase(imageName: String, height: CGFloat) -> some View {
        ZStack {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.38)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
    }

    private func badgeView(text: LocalizedStringKey, icon: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.14), light: LightColors.iconSurface))

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppThemeColor(dark: Theme.Colors.primaryGreen, light: LightColors.iconInk))
            }
            .frame(width: 38, height: 38)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.Colors.primaryGreen.opacity(0.22), lineWidth: 1)
            )

            Text(text)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.95), light: LightColors.primaryText))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer()

            ZStack {
                Circle()
                    .stroke(Theme.Colors.primaryGreen.opacity(0.42), lineWidth: 1)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppThemeColor(dark: Theme.Colors.primaryGreen, light: LightColors.chevron))
            }
            .frame(width: 30, height: 30)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppThemeColor(dark: Color.black.opacity(0.88), light: LightColors.cardSurface))
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
