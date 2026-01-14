import SwiftUI

struct TeacherMyWorkoutsView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo

    private let contentMaxWidth: CGFloat = 380

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
                    let tileHeight = proxy.size.height / 3

                    VStack(spacing: 0) {

                        programaTile(
                            imageName: "rdv_programa_crossfit_horizontal",
                            height: tileHeight,
                            badgeText: "Treinos Crossfit",
                            badgeIcon: "figure.strengthtraining.traditional"
                        ) {
                            path.append(.teacherCrossfitLibrary(section: .benchmarks))
                        }

                        programaTile(
                            imageName: "rdv_programa_academia_horizontal",
                            height: tileHeight,
                            badgeText: "Treinos Academia",
                            badgeIcon: "dumbbell"
                        ) {
                            path.append(.teacherWorkoutTemplates(
                                category: .academia,
                                sectionKey: "meusTreinos",
                                sectionTitle: "Treinos Academia"
                            ))
                        }

                        programaTile(
                            imageName: "rdv_programa_treinos_em_casa_horizontal",
                            height: tileHeight,
                            badgeText: "Treinos em Casa",
                            badgeIcon: "house.fill"
                        ) {
                            path.append(.teacherWorkoutTemplates(
                                category: .emCasa,
                                sectionKey: "meusTreinos",
                                sectionTitle: "Treinos em Casa"
                            ))
                        }
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { pop() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("Biblioteca de Treinos")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
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
        badgeText: String,
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
        .background(
            Color.black.opacity(0.3)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        )
        .frame(height: height)
    }

    private func tileLayout(
        imageName: String,
        height: CGFloat,
        badgeText: String,
        badgeIcon: String
    ) -> some View {

        tileBase(imageName: imageName, height: height)
            .overlay(alignment: .bottomLeading) {
                badgeView(text: badgeText, icon: badgeIcon)
                    // ✅ AQUI: empurra o badge mais para a direita
                    .padding(.leading, 155)
                    .padding(.bottom, 14)
                    .padding(.trailing, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .overlay(Rectangle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
            .clipped()
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
    }

    private func tileBase(imageName: String, height: CGFloat) -> some View {
        ZStack {
            ZStack {
                Color.black

                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: height)
                    .overlay(
                        Rectangle()
                            .fill(Color.black.opacity(0.7))
                            .mask(
                                HStack(spacing: 0) {
                                    LinearGradient(
                                        gradient: Gradient(colors: [.black, .clear]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(width: 28)

                                    Spacer()

                                    LinearGradient(
                                        gradient: Gradient(colors: [.black, .clear]),
                                        startPoint: .trailing,
                                        endPoint: .leading
                                    )
                                    .frame(width: 28)
                                }
                            )
                    )
            }
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)

            LinearGradient(
                colors: [.black.opacity(0.70), .black.opacity(0.15), .clear],
                startPoint: .bottom,
                endPoint: .top
            )

            VStack {
                LinearGradient(colors: [.black.opacity(0.15), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 4)
                Spacer()
                LinearGradient(colors: [.black.opacity(0.15), .clear], startPoint: .bottom, endPoint: .top)
                    .frame(height: 4)
            }
            .frame(height: height)
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
    }

    private func badgeView(text: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.green.opacity(0.90))

            Text(text)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Theme.Colors.cardBackground.opacity(0.92))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 3)
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

