import SwiftUI

struct TeacherDashboardView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo
    @Environment(\.selectTeacherMainSection) private var selectTeacherMainSection
    @EnvironmentObject private var session: AppSession

    private let contentMaxWidth: CGFloat = 380
    private let summaryColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
    private let quickAccessColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

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

                            summaryCard

                            quickAccessCard

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
            Text(greeting)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)

            Text("Acompanhando a evolução da sua turma.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Resumo de hoje")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white.opacity(0.92))

                Spacer()

                Text(todayText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))
            }

            LazyVGrid(columns: summaryColumns, spacing: 8) {
                summaryItem(value: 0, title: "Alunos com treino", icon: "person.3.fill")
                summaryItem(value: 0, title: "Treinos concluídos", icon: "checkmark.circle.fill")
                summaryItem(value: 0, title: "Em andamento", icon: "clock.fill")
                summaryItem(value: 0, title: "Sem treino", icon: "exclamationmark.triangle.fill")
            }
        }
        .padding(14)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var quickAccessCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Acesso rápido")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white.opacity(0.92))

            LazyVGrid(columns: quickAccessColumns, spacing: 12) {
                quickAccessItem(
                    title: "Meus alunos",
                    subtitle: "Gerencie sua turma",
                    icon: "person.3.fill"
                ) {
                    selectTeacherMainSection(.students)
                }

                quickAccessItem(
                    title: "Biblioteca de Treinos",
                    subtitle: "Use modelos prontos",
                    icon: "square.grid.2x2.fill"
                ) {
                    path.append(.teacherMyWorkouts(category: category, mode: .library))
                }

                quickAccessItem(
                    title: "Importar",
                    subtitle: "De competições ou bibliotecas",
                    icon: "tablecells.fill"
                ) {
                    path.append(.teacherImportWorkouts(category: category))
                }

                quickAccessItem(
                    title: "Meus Vídeos",
                    subtitle: "Organize seus vídeos de movimentos",
                    icon: "video.fill"
                ) {
                    path.append(.teacherImportVideos(category: category))
                }
            }
        }
        .padding(14)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var greeting: String {
        let name = session.userName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Olá, Professor!" : "Olá, \(name)!"
    }

    private var todayText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE, dd/MM"
        let date = formatter.string(from: Date())
        guard let first = date.first else { return date }
        return first.uppercased() + String(date.dropFirst())
    }

    private func summaryItem(value: Int, title: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.green.opacity(0.85))

            Text("\(value)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white.opacity(0.92))

            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.62))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 118)
        .padding(.horizontal, 6)
        .background(Theme.Colors.cardBackground.opacity(0.72))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func quickAccessItem(
        title: String,
        subtitle: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.green.opacity(0.85))
                    .font(.system(size: 16))
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(2)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(3)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))
                    .font(.system(size: 12, weight: .semibold))
            }
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .padding(12)
            .background(Theme.Colors.cardBackground.opacity(0.72))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
