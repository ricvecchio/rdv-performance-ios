import SwiftUI

// MARK: - Aluno: Detalhe do Dia (MVP)
struct StudentDayDetailView: View {

    @Binding var path: [AppRoute]
    let day: TrainingDayFS
    let weekTitle: String

    @EnvironmentObject private var session: AppSession

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
                    VStack(spacing: 16) {
                        header
                        trainingCard
                        blocksCard
                    }
                    .frame(maxWidth: contentMaxWidth)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                    .frame(maxWidth: .infinity)
                }

                footer
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
                Text("Dia de treino")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                MiniProfileHeader(imageName: "rdv_eu", size: 38)
                    .background(Color.clear)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var footer: some View {
        FooterBar(
            path: $path,
            kind: .agendaSobrePerfil(
                isAgendaSelected: true,
                isSobreSelected: false,
                isPerfilSelected: false
            )
        )
        .frame(height: Theme.Layout.footerHeight)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.footerBackground)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {

            Text("Semana: \(weekTitle)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.55))

            Text(day.subtitleText)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var trainingCard: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Treino")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))

            VStack(alignment: .leading, spacing: 6) {
                Text(day.title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                if let dateText = formattedDate(day.date) {
                    Text(dateText)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.45))
                }

                if !day.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(day.description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    // ✅ Sem “Blocos” e alinhado à esquerda igual ao card Treino
    private var blocksCard: some View {
        VStack(alignment: .leading, spacing: 10) {

            if day.blocks.isEmpty {
                Text("Nenhum bloco cadastrado.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(day.blocks.enumerated()), id: \.offset) { idx, block in
                        VStack(alignment: .leading, spacing: 6) {

                            Text(block.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.92))

                            if !block.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(block.details)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.65))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.vertical, 12)

                        if idx < day.blocks.count - 1 {
                            innerDivider(leading: 0)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private func innerDivider(leading: CGFloat) -> some View {
        Divider()
            .background(Theme.Colors.divider)
            .padding(.leading, leading)
    }

    private func formattedDate(_ date: Date?) -> String? {
        guard let date else { return nil }
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

