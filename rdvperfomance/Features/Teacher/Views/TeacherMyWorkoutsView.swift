import SwiftUI

struct TeacherMyWorkoutsView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo
    let mode: TeacherWorkoutsMode
    @Environment(\.locale) private var locale

    private let contentMaxWidth: CGFloat = 410

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
                            .foregroundColor(.green)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("ui.workout_library")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
        .background(Color.black.opacity(0.76))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: Theme.Colors.primaryGreen.opacity(0.12), radius: 6, y: 2)
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
                    .fill(Theme.Colors.primaryGreen.opacity(0.14))

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryGreen)
            }
            .frame(width: 38, height: 38)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.Colors.primaryGreen.opacity(0.22), lineWidth: 1)
            )

            Text(text)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer()

            ZStack {
                Circle()
                    .stroke(Theme.Colors.primaryGreen.opacity(0.42), lineWidth: 1)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryGreen)
            }
            .frame(width: 30, height: 30)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.88))
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
