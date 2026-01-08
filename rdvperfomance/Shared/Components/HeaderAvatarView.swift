// Avatar do cabeçalho que exibe foto do perfil com cache otimizado
import SwiftUI
import UIKit

// View de avatar que carrega foto do usuário do armazenamento local
struct HeaderAvatarView: View {

    @EnvironmentObject private var session: AppSession

    var size: CGFloat = 38
    var showStroke: Bool = true
    var strokeOpacity: Double = 0.15

    // Cache em memória para evitar recarregamentos desnecessários
    @State private var cachedImage: UIImage? = nil

    // Gerencia o carregamento e atualização da imagem do perfil
    var body: some View {
        content
            .onAppear {
                reloadImageIfNeeded()
            }
            .onChange(of: session.currentUid) { _, _ in
                reloadImage(force: true)
            }
            .onReceive(NotificationCenter.default.publisher(for: LocalProfileStore.Notifications.profilePhotoDidChange)) { note in
                let changedUserId = note.userInfo?[LocalProfileStore.Notifications.userIdKey] as? String
                let current = (session.currentUid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

                guard !current.isEmpty else { return }

                if changedUserId == current {
                    reloadImage(force: true)
                }
            }
    }

    // Retorna a imagem do usuário ou fallback padrão
    @ViewBuilder
    private var content: some View {
        if let img = cachedImage {
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

    // Recarrega a imagem se necessário
    private func reloadImageIfNeeded() {
        reloadImage(force: false)
    }

    // Recarrega a imagem do armazenamento local
    private func reloadImage(force: Bool) {
        let newImage = LocalProfileStore.shared.getPhotoImage(userId: session.currentUid)

        if force {
            cachedImage = newImage
            return
        }

        if !imagesEqual(lhs: cachedImage, rhs: newImage) {
            cachedImage = newImage
        }
    }

    // Compara duas imagens para evitar atualizações desnecessárias
    private func imagesEqual(lhs: UIImage?, rhs: UIImage?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case (nil, _), (_, nil):
            return false
        case (let a?, let b?):
            return a.pngData() == b.pngData()
        }
    }
}

