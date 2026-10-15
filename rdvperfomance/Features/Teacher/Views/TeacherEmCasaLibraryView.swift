import SwiftUI

struct TeacherEmCasaLibraryView: View {

    @Binding var path: [AppRoute]
    let mode: TeacherWorkoutsMode
    let templateMode: TeacherWorkoutTemplatesMode
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

    private let contentMaxWidth: CGFloat = 380

    private struct MenuItem: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let sectionKey: String
    }

    private var menuItems: [MenuItem] {
        [
            .init(title: AppLocalization.string("ui.chest", locale: locale), sectionKey: "peito"),
            .init(title: AppLocalization.string("ui.back", locale: locale), sectionKey: "costas"),
            .init(title: AppLocalization.string("ui.legs", locale: locale), sectionKey: "pernas"),
            .init(title: AppLocalization.string("ui.shoulders", locale: locale), sectionKey: "ombros"),
            .init(title: AppLocalization.string("ui.arms", locale: locale), sectionKey: "bracos"),
            .init(title: AppLocalization.string("ui.core_abs", locale: locale), sectionKey: "core"),
            .init(title: AppLocalization.string("ui.full_body", locale: locale), sectionKey: "fullBody"),
            .init(title: AppLocalization.string("ui.my_workouts", locale: locale), sectionKey: "meusTreinos")
        ]
    }

    var body: some View {
        ZStack {

            AppThemeBackgroundImage()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {
                            VStack(spacing: 10) {
                                ForEach(menuItems) { item in
                                    actionRow(title: item.title, icon: "house.fill") {
                                        if templateMode == .attach {
                                            path.append(.teacherWorkoutTemplates(
                                                category: .emCasa,
                                                sectionKey: item.sectionKey,
                                                sectionTitle: item.title,
                                                mode: .attach
                                            ))
                                        } else {
                                            switch mode {
                                            case .library:
                                                path.append(.teacherWorkoutTemplates(
                                                    category: .emCasa,
                                                    sectionKey: item.sectionKey,
                                                    sectionTitle: item.title
                                                ))
                                            case .create:
                                                path.append(.createTreinoCasa(
                                                    category: .emCasa,
                                                    sectionKey: item.sectionKey,
                                                    sectionTitle: item.title
                                                ))
                                            }
                                        }
                                    }
                                }
                            }
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
                        selectedCategory: .emCasa,
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
                Text("ui.home_workouts")
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

    private func actionRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.14), light: LightColors.iconSurface))

                    Image(systemName: icon)
                        .foregroundStyle(AppThemeColor(dark: Theme.Colors.primaryGreen, light: LightColors.iconInk))
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(width: 42, height: 42)
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(Theme.Colors.primaryGreen.opacity(0.22), lineWidth: 1)
                )

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.35), light: LightColors.chevron))
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    // Mesma tonalidade dos botões da TeacherWorkoutsView
                    AppThemeColor(dark: Color.black.opacity(0.90), light: LightColors.cardSurface)
                    AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.05), light: .clear)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1)
            )
            // Tema Claro: mesma profundidade da AdminProfileSelectionView (Tema Escuro: sem sombra)
            .shadow(
                color: appTheme == .light ? .black.opacity(0.25) : .clear,
                radius: appTheme == .light ? 10 : 0,
                y: appTheme == .light ? 6 : 0
            )
        }
        .buttonStyle(.plain)
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
