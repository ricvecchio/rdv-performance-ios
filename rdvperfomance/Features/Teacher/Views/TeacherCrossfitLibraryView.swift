import SwiftUI

struct TeacherCrossfitLibraryView: View {

    @Binding var path: [AppRoute]
    let section: CrossfitLibrarySection
    let mode: TeacherWorkoutsMode
    let templateMode: TeacherWorkoutTemplatesMode
    @Environment(\.locale) private var locale

    private let contentMaxWidth: CGFloat = 380

    // ✅ Itens fixos conforme solicitado (ordem + nomes)
    private struct CrossfitMenuItem: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let sectionKey: String
    }

    // ✅ Chaves estáveis para o Firestore (mantidas como strings para não depender do enum)
    // Importante: se suas keys reais no Firestore forem diferentes, ajuste SOMENTE os valores abaixo.
    private var menuItems: [CrossfitMenuItem] {
        [
            .init(title: AppLocalization.string("library.crossfit.girls_wods", locale: locale), sectionKey: "girlsWods"),
            .init(title: AppLocalization.string("library.crossfit.hero_tribute_workouts", locale: locale), sectionKey: "heroTributeWorkouts"),
            .init(title: AppLocalization.string("library.crossfit.open_wods", locale: locale), sectionKey: "openWods"),
            .init(title: AppLocalization.string("library.crossfit.named_wods", locale: locale), sectionKey: "wodsNomeados"),
            .init(title: AppLocalization.string("library.crossfit.qualifier_competition_wods", locale: locale), sectionKey: "qualifiersCompeticoes"),
            .init(title: AppLocalization.string("ui.my_workouts", locale: locale), sectionKey: "meusTreinos")
        ]
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

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {
                            VStack(spacing: 14) {
                                ForEach(menuItems) { item in
                                    actionRow(title: item.title, icon: "figure.strengthtraining.traditional") {
                                        if templateMode == .attach {
                                            path.append(.teacherWorkoutTemplates(
                                                category: .crossfit,
                                                sectionKey: item.sectionKey,
                                                sectionTitle: item.title,
                                                mode: .attach
                                            ))
                                        } else {
                                            switch mode {
                                            case .library:
                                                path.append(.teacherWorkoutTemplates(
                                                    category: .crossfit,
                                                    sectionKey: item.sectionKey,
                                                    sectionTitle: item.title
                                                ))
                                            case .create:
                                            path.append(.createCrossfitWOD(
                                                category: .crossfit,
                                                sectionKey: item.sectionKey,
                                                sectionTitle: item.title
                                            ))
                                            }
                                        }
                                    }
                                }
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
                        selectedCategory: .crossfit,
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
                Text("video.category.crossfit")
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

    private func actionRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Theme.Colors.primaryGreen.opacity(0.14))

                    Image(systemName: icon)
                        .foregroundColor(Theme.Colors.primaryGreen)
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(width: 42, height: 42)
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(Theme.Colors.primaryGreen.opacity(0.22), lineWidth: 1)
                )

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    Color.black.opacity(0.68)
                    Theme.Colors.primaryGreen.opacity(0.05)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
