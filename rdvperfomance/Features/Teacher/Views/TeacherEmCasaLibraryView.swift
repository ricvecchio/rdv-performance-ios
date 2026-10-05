import SwiftUI

struct TeacherEmCasaLibraryView: View {

    @Binding var path: [AppRoute]
    let mode: TeacherWorkoutsMode
    let templateMode: TeacherWorkoutTemplatesMode
    @Environment(\.locale) private var locale

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
                            VStack(spacing: 7) {
                                ForEach(menuItems) { item in
                                    actionRow(title: item.title, icon: "folder.fill") {
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
                        .padding(.top, 10)

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
                            .foregroundColor(.green)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("ui.home_workouts")
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
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.Colors.primaryGreen.opacity(0.14))

                    Image(systemName: icon)
                        .foregroundColor(Theme.Colors.primaryGreen)
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(width: 36, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
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
            .padding(.vertical, 9)
            .background(Color.black.opacity(0.76))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
            )
            .shadow(color: Theme.Colors.primaryGreen.opacity(0.12), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
