import SwiftUI

struct TreinosView: View {

    @Binding var path: [AppRoute]
    let tipo: TreinoTipo

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

                GeometryReader { proxy in
                    let maxContentWidth = min(proxy.size.width - 32, 520)

                    VStack {
                        Spacer(minLength: 12)

                        ZStack(alignment: .bottom) {
                            Image(tipo.imagemCorpo)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: maxContentWidth)
                                .shadow(color: .black.opacity(0.5), radius: 10, y: 6)

                            Text(tipo.tituloOverlayImagem)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.95), radius: 8, x: 0, y: 3)
                                .padding(.bottom, 22)
                                .padding(.horizontal, 22)
                                .frame(maxWidth: maxContentWidth, alignment: .center)
                        }

                        Spacer(minLength: 12)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 16)
                }

                FooterBar(
                    path: $path,
                    kind: .treinosComPerfil(
                        treinoTitle: tipo.titulo,
                        treinoIcon: AnyView(tipo.iconeRodapeTreinos),
                        isHomeSelected: false,
                        isTreinoSelected: true,
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
            }

            ToolbarItem(placement: .principal) {
                Text(tipo.titulo)
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                MiniProfileHeader(imageName: "rdv_user_default", size: 38)
                    .onTapGesture { }
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

