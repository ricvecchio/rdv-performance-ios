import SwiftUI

struct TeacherWorkoutsCategoryView: View {

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

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {

                            Text("Categoria selecionada: \(category.displayName)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.green.opacity(0.85))

                            Text("Escolha uma seção para ver/criar templates.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.55))

                            VStack(spacing: 12) {

                                if category == .crossfit {
                                    actionRow(title: "Abrir biblioteca Crossfit", icon: "list.bullet.rectangle.portrait") {
                                        // Por padrão, podemos começar em "Benchmarks"
                                        path.append(.teacherCrossfitLibrary(section: .benchmarks))
                                    }
                                } else {
                                    // Academia / Em Casa: já direciona para uma seção genérica “meusTreinos”
                                    actionRow(title: "Meus Treinos", icon: "square.grid.2x2.fill") {
                                        path.append(.teacherWorkoutTemplates(
                                            category: category,
                                            sectionKey: "meusTreinos",
                                            sectionTitle: "Meus Treinos"
                                        ))
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
                Text(category.displayName)
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

    private func actionRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.green.opacity(0.85))
                    .font(.system(size: 16))
                    .frame(width: 26)

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
