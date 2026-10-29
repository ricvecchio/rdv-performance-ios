import SwiftUI

struct TeacherWorkoutsView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo
    @Environment(\.selectTeacherMainSection) private var selectTeacherMainSection

    @Environment(\.appTheme) private var appTheme

    private let contentMaxWidth: CGFloat = 380

    // Cores locais exclusivas do Tema Claro (padrao da TrainingWeeksView; Tema Escuro usa sempre os valores originais)
    private enum LightColors {
        static let cardSurface = Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)   // #DDEDDC
        static let iconSurface = Color(red: 0x85 / 255, green: 0xC9 / 255, blue: 0x95 / 255)   // #85C995
        static let iconInk = Color(red: 0x25 / 255, green: 0x48 / 255, blue: 0x2B / 255)       // #25482B
        static let primaryText = Color(red: 0x17 / 255, green: 0x1C / 255, blue: 0x17 / 255)   // #171C17
        static let chevron = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)       // #294A2F
        static let border = Color(red: 0xC9 / 255, green: 0xDF / 255, blue: 0xC9 / 255)        // #C9DFC9
    }

    var body: some View {
        ZStack {

            AppThemeBackgroundImage()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                ScrollView(.vertical, showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 24) {
                            quickAccessCard(
                                title: "ui.send_workout",
                                subtitle: "ui.send_a_workout_to_your_students",
                                icon: "paperplane.fill"
                            ) {
                                path.append(
                                    .teacherSendWorkout(
                                        preselectedStudentID: nil,
                                        startsAtWorkout: false
                                    )
                                )
                            }

                            quickAccessCard(
                                title: "ui.create_workout",
                                subtitle: "ui.create_a_new_workout",
                                icon: "plus.circle.fill"
                            ) {
                                path.append(.teacherMyWorkouts(category: category, mode: .create))
                            }

                            quickAccessCard(
                                title: "ui.workout_library",
                                subtitle: "ui.use_ready_made_templates",
                                icon: "square.grid.2x2.fill"
                            ) {
                                path.append(.teacherMyWorkouts(category: category, mode: .library))
                            }

                            quickAccessCard(
                                title: "tecnofit_import.import_action",
                                subtitle: "ui.import_workouts_from_a_spreadsheet",
                                icon: "doc.text.fill"
                            ) {
                                path.append(.teacherImportWorkouts(category: category))
                            }


                            quickAccessCard(
                                title: "workout.my_videos",
                                subtitle: "ui.organize_your_videos",
                                icon: "video.fill"
                            ) {
                                path.append(.teacherImportVideos(category: category))
                            }
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 16)

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

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
                Button { selectTeacherMainSection(.menu) } label: {
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
                Text("ui.workouts")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundStyle(Theme.Colors.ink())
            }

            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appThemeNavigationBarColorScheme()
    }

    private func quickAccessCard(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(AppThemeColor(dark: Color.green.opacity(0.14), light: LightColors.iconSurface))
                        .frame(width: 34, height: 34)

                    Image(systemName: icon)
                        .foregroundStyle(AppThemeColor(dark: Color.green.opacity(0.85), light: LightColors.iconInk))
                        .font(.system(size: 16, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                        .lineLimit(2)

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.ink(0.55))
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.35), light: LightColors.chevron))
            }
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    // Equivale ao botão (0.68) sobre o card escuro (0.68) do Acesso rápido: 1 - 0.32 * 0.32 ≈ 0.90
                    AppThemeColor(dark: Color.black.opacity(0.90), light: LightColors.cardSurface)
                    AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.05), light: .clear)
                }
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.chevron), lineWidth: 1)
            )
            // Tema Claro: mesma profundidade da AdminProfileSelectionView (Tema Escuro: sem sombra)
            .shadow(
                color: appTheme == .light ? .black.opacity(0.25) : .clear,
                radius: appTheme == .light ? 10 : 0,
                y: appTheme == .light ? 6 : 0
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}
