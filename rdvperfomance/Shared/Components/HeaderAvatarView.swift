import SwiftUI
import UIKit

// MARK: - HeaderAvatarView
/// Avatar único para cabeçalho (NavigationBar).
/// ✅ Busca a foto do usuário logado via LocalProfileStore (por UID)
/// ✅ Fallback automático para asset (rdv_user_default)
/// ✅ Sem repetir código nas telas
struct HeaderAvatarView: View {

    @EnvironmentObject private var session: AppSession

    var size: CGFloat = 38
    var showStroke: Bool = true
    var strokeOpacity: Double = 0.15

    // Recarrega quando:
    // - usuário muda (uid muda)
    // - foto é salva/removida em Settings/EditProfile (UserDefaults muda)
    @State private var refreshToken: UUID = UUID()

    var body: some View {
        content
            .id(refreshToken) // força refresh do ViewBuilder quando necessário
            .onAppear { refreshToken = UUID() }
            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                refreshToken = UUID()
            }
            .onChange(of: session.currentUid) { _, _ in
                refreshToken = UUID()
            }
    }

    @ViewBuilder
    private var content: some View {
        if let img = LocalProfileStore.shared.getPhotoImage(userId: session.currentUid) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(
                    Group {
                        if showStroke {
                            Circle().stroke(Color.white.opacity(strokeOpacity), lineWidth: 1)
                        }
                    }
                )
                .contentShape(Circle())
                .accessibilityLabel("Perfil")
        } else {
            MiniProfileHeader(imageName: "rdv_user_default", size: size)
        }
    }
}

