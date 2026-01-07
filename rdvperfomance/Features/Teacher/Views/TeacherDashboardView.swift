// TeacherDashboardView.swift — Painel inicial do professor com ações rápidas
import SwiftUI

struct TeacherDashboardView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo

    private let contentMaxWidth: CGFloat = 380

    // Corpo com ações principais (Meus alunos, Publicar semana)
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

                                actionRow(
                                    title: "Meus alunos",
                                    icon: "person.3.fill"
                                ) {
                                    path.append(.teacherStudentsList(selectedCategory: category, initialFilter: nil))
                                }

                                actionRow(
                                    title: "Publicar semana",
                                    icon: "calendar.badge.plus"
                                ) {
                                    path.append(.teacherStudentsList(selectedCategory: category, initialFilter: nil))
                                }

                                // Restaurar: Mapa da Academia
                                actionRow(
                                    title: "Mapa da Academia",
                                    icon: "map.fill"
                                ) {
                                    path.append(.mapFeature)
                                }

                                // Visualizar no ambiente (AR) — professor
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
        .toolbar {

            ToolbarItem(placement: .navigationBarLeading) {
                Button { pop() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("Área do Professor")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            // Avatar do cabeçalho (foto real do usuário)
            ToolbarItem(placement: .navigationBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Aqui você gerencia alunos e publica treinos da semana.")
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
