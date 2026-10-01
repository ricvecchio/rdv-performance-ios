import SwiftUI

struct ForceUpdateView: View {
    let config: AppVersionConfig

    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image("rdv_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220)
                    .opacity(0.9)

                VStack(spacing: 12) {
                    Text("Atualização necessária")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    if let message = config.message {
                        Text(message)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.82))
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Uma nova versão do RDV Performance está disponível. Atualize o aplicativo para continuar.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.82))
                            .multilineTextAlignment(.center)
                    }
                }

                Button("ATUALIZAR AGORA") {
                    openAppStore()
                }
                .frame(maxWidth: .infinity)
                .primaryGreenActionButton()
                .buttonStyle(.plain)
            }
            .frame(maxWidth: 300)
            .padding(24)
        }
    }

    private func openAppStore() {
        guard
            let url = URL(string: config.appStoreURL),
            let scheme = url.scheme?.lowercased(),
            ["https", "itms-apps"].contains(scheme),
            url.host != nil
        else {
            return
        }

        openURL(url)
    }
}
