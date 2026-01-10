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

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {

                        Text("Escolha a categoria para gerenciar seus treinos.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.55))

                        VStack(spacing: 12) {

                            // ✅ Agora vai direto para a biblioteca Crossfit (sem tela intermediária)
                            menuRow(title: "Treinos Crossfit", icon: "figure.strengthtraining.traditional") {
                                path.append(.teacherCrossfitLibrary(section: .benchmarks))
                            }

                            // ✅ Agora vai direto para a lista de templates (sem tela intermediária)
                            menuRow(title: "Treinos Academia", icon: "dumbbell") {
                                path.append(.teacherWorkoutTemplates(
                                    category: .academia,
                                    sectionKey: "meusTreinos",
                                    sectionTitle: "Meus Treinos"
                                ))
                            }

                            // ✅ Agora vai direto para a lista de templates (sem tela intermediária)
                            menuRow(title: "Treinos em Casa", icon: "house.fill") {
                                path.append(.teacherWorkoutTemplates(
                                    category: .emCasa,
                                    sectionKey: "meusTreinos",
                                    sectionTitle: "Meus Treinos"
                                ))
                            }
                        }

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

    private func menuRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.green.opacity(0.85))
                    .font(.system(size: 18))
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

