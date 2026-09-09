import SwiftUI

struct TeacherWorkoutsView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo
    @Environment(\.selectTeacherMainSection) private var selectTeacherMainSection

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

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {

                            header

                            VStack(spacing: 14) {
                                quickAccessCard(
                                    title: "Criar treino",
                                    subtitle: "Monte um novo treino",
                                    icon: "plus.circle.fill"
                                ) {
                                    path.append(.teacherMyWorkouts(category: category, mode: .create))
                                }

                                quickAccessCard(
                                    title: "Biblioteca de Treinos",
                                    subtitle: "Use modelos prontos",
                                    icon: "square.grid.2x2.fill"
                                ) {
                                    path.append(.teacherMyWorkouts(category: category, mode: .library))
                                }

                                quickAccessCard(
                                    title: "Importar",
                                    subtitle: "Importe treinos por planilha",
                                    icon: "doc.text.fill"
                                ) {
                                    path.append(.teacherImportWorkouts(category: category))
                                }

                                quickAccessCard(
                                    title: "Meus Vídeos",
                                    subtitle: "Organize seus vídeos",
                                    icon: "video.fill"
                                ) {
                                    path.append(.teacherImportVideos(category: category))
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
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            ToolbarItem(placement: .topBarLeading) {
                Button { selectTeacherMainSection(.home) } label: {
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
                Text("Treinos")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gerencie sua biblioteca, importe treinos e organize seus vídeos.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func quickAccessCard(
        title: String,
        subtitle: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color.green.opacity(0.14))
                        .frame(width: 34, height: 34)

                    Image(systemName: icon)
                        .foregroundColor(.green.opacity(0.85))
                        .font(.system(size: 16, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(2)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))
                    .font(.system(size: 12, weight: .semibold))
            }
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}
