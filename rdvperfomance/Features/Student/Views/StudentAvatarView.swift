import SwiftUI
import UIKit

struct StudentAvatarView: View {

    let base64: String?
    var size: CGFloat = 32

    var body: some View {
        if let img = decodeImage() {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
        } else {
            // ✅ Ajuste pedido: avatar_default (rdv_user_default) em vez do ícone verde
            Image("rdv_user_default")
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
    }

    private func decodeImage() -> UIImage? {
        var raw = (base64 ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }

        // ✅ Suporta "data:image/jpeg;base64,...."
        if let commaIndex = raw.firstIndex(of: ","),
           raw.lowercased().contains("base64") {
            raw = String(raw[raw.index(after: commaIndex)...])
        }

        // ✅ Mais tolerante a quebras de linha / caracteres inválidos
        guard let data = Data(base64Encoded: raw, options: [.ignoreUnknownCharacters]) else { return nil }
        return UIImage(data: data)
    }
}

