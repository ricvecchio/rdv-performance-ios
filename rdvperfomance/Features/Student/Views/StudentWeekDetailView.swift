import SwiftUI

// MARK: - Tela 7 (Aluno): Treinos da Semana (Detalhe)
struct StudentWeekDetailView: View {

    @Binding var path: [AppRoute]

    let week: TrainingWeek

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

                        VStack(spacing: 14) {

                            headerCard()

                            daysCard()

                            Color.clear
                                .frame(height: Theme.Layout.footerHeight + 20)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                }

                // ✅ Aluno: Agenda | Treinos | Sobre | Perfil (Treinos selecionado)
                FooterBar(
                    path: $path,
                    kind: .agendaTreinosSobrePerfil(
                        isAgendaSelected: false,
                        isTreinosSelected: true,
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

            // ✅ Botão voltar aqui faz sentido (volta para a Agenda)
            ToolbarItem(placement: .navigationBarLeading) {
                Button { pop() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("Treinos da Semana")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                MiniProfileHeader(imageName: "rdv_eu", size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func headerCard() -> some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Resumo")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.55))

            Text("Aqui você verá o detalhamento do treino da semana (Segunda a Sábado).")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func daysCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Treinos (01 a 06)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.55))

            VStack(spacing: 10) {
                dayRow(day: "Segunda", detail: "Treino 01 — (resumo)")
                dayRow(day: "Terça", detail: "Treino 02 — (resumo)")
                dayRow(day: "Quarta", detail: "Treino 03 — (resumo)")
                dayRow(day: "Quinta", detail: "Treino 04 — (resumo)")
                dayRow(day: "Sexta", detail: "Treino 05 — (resumo)")
                dayRow(day: "Sábado", detail: "Treino 06 — (resumo)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func dayRow(day: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(day)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.95))

            Text(detail)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.70))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)

        // divisor sutil
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

