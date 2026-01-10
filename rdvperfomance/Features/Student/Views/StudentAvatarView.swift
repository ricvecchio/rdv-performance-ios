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
            // ✅ Corrigido: fallback é avatar_default (e não ícone verde)
            ZStack {
                // Se o asset não existir, o SF Symbol abaixo ainda garante que nada "some"
                Image("avatar_default")
                    .resizable()
                    .scaledToFill()

                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: size))
                    .foregroundColor(.white.opacity(0.08))
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
    }

    private func decodeImage() -> UIImage? {
        let raw = (base64 ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        guard let data = Data(base64Encoded: raw) else { return nil }
        return UIImage(data: data)
    }
}

