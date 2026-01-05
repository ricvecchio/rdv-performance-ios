// HeaderAvatarView.swift — Avatar do cabeçalho que usa foto local com fallback
import SwiftUI
import UIKit

struct HeaderAvatarView: View {

    @EnvironmentObject private var session: AppSession

    var size: CGFloat = 38
    var showStroke: Bool = true
    var strokeOpacity: Double = 0.15

    // Recarrega a view quando UserDefaults muda ou uid muda
    @State private var refreshToken: UUID = UUID()

    var body: some View {
        content
            .id(refreshToken)
            .onAppear { refreshToken = UUID() }
            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                refreshToken = UUID()
            }
            .onChange(of: session.currentUid) { _, _ in
                refreshToken = UUID()
            }
    }

    // Conteúdo condicional: imagem salva ou fallback
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
