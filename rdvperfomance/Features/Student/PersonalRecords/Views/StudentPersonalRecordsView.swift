import SwiftUI

// Tela do Aluno: Recorde Pessoal (menu de seções)
struct StudentPersonalRecordsView: View {

    @Binding var path: [AppRoute]

    private let contentMaxWidth: CGFloat = 380

    private struct PRMenuItem: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let sectionKey: String
    }

    // Itens fixos conforme solicitado (ordem + nomes)
    private let menuItems: [PRMenuItem] = [
        .init(title: "Barbell", sectionKey: "barbell"),
        .init(title: "Gymnastic", sectionKey: "gymnastic"),
        .init(title: "Endurance", sectionKey: "endurance"),
        .init(title: "Notables", sectionKey: "notables"),
        .init(title: "Girls", sectionKey: "girls"),
        .init(title: "Open", sectionKey: "open"),
        .init(title: "The Heroes", sectionKey: "theHeroes"),
        .init(title: "Campeonatos", sectionKey: "campeonatos"),
        .init(title: "Crossfit Games", sectionKey: "crossfitGames")
    ]

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

                            Text("Selecione uma seção.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.55))

                            VStack(spacing: 12) {
                                ForEach(menuItems) { item in
                                    actionRow(title: item.title, icon: "folder.fill") {

                                        if item.sectionKey == "barbell" {
                                            path.append(.studentPersonalRecordsBarbell)
                                        }

                                        if item.sectionKey == "gymnastic" {
                                            path.append(.studentPersonalRecordsGymnastic)
                                        }

                                        if item.sectionKey == "endurance" {
                                            path.append(.studentPersonalRecordsEndurance)
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
                    kind: .agendaSobrePerfil(
                        isAgendaSelected: false,
                        isSobreSelected: true,
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
                Text("Recorde Pessoal")
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

