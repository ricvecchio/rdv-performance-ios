import SwiftUI

struct TeacherDashboardView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo

    private let contentMaxWidth: CGFloat = 380

    @State private var isImportExcelSheetPresented: Bool = false

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

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {

                            header

                            VStack(spacing: 12) {

                                // 1) Biblioteca de Treinos -> ✅ AGORA: TeacherMyWorkoutsView
                                actionRow(
                                    title: "Biblioteca de Treinos",
                                    icon: "square.grid.2x2.fill"
                                ) {
                                    path.append(.teacherMyWorkouts(category: category))
                                }

                                // 2) Meus Alunos
                                actionRow(
                                    title: "Meus alunos",
                                    icon: "person.3.fill"
                                ) {
                                    path.append(.teacherStudentsList(selectedCategory: category, initialFilter: nil))
                                }

                                // 3) Importar Excel
                                actionRow(
                                    title: "Importar Treino",
                                    icon: "tablecells.fill"
                                ) {
                                    isImportExcelSheetPresented = true
                                }

                                // ✅ 3.1) NOVO: Importar Vídeos
                                actionRow(
                                    title: "Importar Vídeos",
                                    icon: "video.fill"
                                ) {
                                    path.append(.teacherImportVideos(category: category))
                                }

                                // 4) Mapa da Academia
                                actionRow(
                                    title: "Mapa da Academia",
                                    icon: "map.fill"
                                ) {
                                    path.append(.mapFeature)
                                }

                                // 5) Visualizar no ambiente
                                actionRow(
                                    title: "Visualizar no ambiente",
                                    icon: "viewfinder"
                                ) {
                                    path.append(.arDemo)
                                }
                            }
                            .padding(.top, 8)

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
                        isHomeSelected: true,
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

            ToolbarItem(placement: .principal) {
                Text("Área do Professor")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $isImportExcelSheetPresented) {
            TeacherImportExcelSheet()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Aqui você gerencia alunos e seus treinos.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

// MARK: - Sheet Importar Treino
private struct TeacherImportExcelSheet: View {

    @Environment(\.dismiss) private var dismiss

    private let contentMaxWidth: CGFloat = 420

    var body: some View {
        ZStack {

            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {

                Text("Importar Treino")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)

                Text("Aqui você poderá importar treinos via planilha (Excel/CSV).")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.65))

                Spacer(minLength: 0)

                Button {
                    dismiss()
                } label: {
                    Text("Fechar")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.Colors.cardBackground)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .frame(maxWidth: contentMaxWidth)
        }
    }
}

