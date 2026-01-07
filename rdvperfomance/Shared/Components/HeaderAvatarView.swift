// HeaderAvatarView.swift — Avatar do cabeçalho que usa foto local com fallback
import SwiftUI
import UIKit

struct HeaderAvatarView: View {

    @EnvironmentObject private var session: AppSession

    var size: CGFloat = 38
    var showStroke: Bool = true
    var strokeOpacity: Double = 0.15

    // ✅ Cache da imagem em memória (evita buscar toda hora no body)
    @State private var cachedImage: UIImage? = nil

    var body: some View {
        content
            .onAppear {
                // ✅ Carrega uma vez ao aparecer
                reloadImageIfNeeded()
            }
            .onChange(of: session.currentUid) { _, _ in
                // ✅ Troca de usuário → recarrega
                reloadImage(force: true)
            }
            .onReceive(NotificationCenter.default.publisher(for: LocalProfileStore.Notifications.profilePhotoDidChange)) { note in
                // ✅ Atualiza SOMENTE quando a foto do usuário atual mudar
                let changedUserId = note.userInfo?[LocalProfileStore.Notifications.userIdKey] as? String
                let current = (session.currentUid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

                // Se o usuário atual estiver vazio, não faz nada (evita churn)
                guard !current.isEmpty else { return }

                if changedUserId == current {
                    reloadImage(force: true)
                }
            }
    }

    // Conteúdo condicional: imagem salva ou fallback
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

    // MARK: - Helpers

    /// Recarrega se houver uid e se a imagem mudou (barato e seguro).
    private func reloadImageIfNeeded() {
        reloadImage(force: false)
    }

    /// Recarrega a imagem do armazenamento local.
    /// - Parameter force: se true, sempre recarrega. Se false, só atualiza se mudar.
    private func reloadImage(force: Bool) {
        let newImage = LocalProfileStore.shared.getPhotoImage(userId: session.currentUid)

        if force {
            cachedImage = newImage
            return
        }

        // ✅ Evita setState desnecessário (que invalida a toolbar)
        if !imagesEqual(lhs: cachedImage, rhs: newImage) {
            cachedImage = newImage
        }
    }

    /// Comparação simples para evitar updates repetidos.
    private func imagesEqual(lhs: UIImage?, rhs: UIImage?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case (nil, _), (_, nil):
            return false
        case (let a?, let b?):
            // Comparação por PNG data é suficiente aqui (e só roda quando reloadImage é chamado)
            return a.pngData() == b.pngData()
        }
    }
}

