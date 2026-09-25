import UIKit

enum ProfilePhotoProcessingError: LocalizedError {
    case unableToProcess

    var errorDescription: String? {
        "Não foi possível processar a foto selecionada. Escolha outra imagem e tente novamente."
    }
}

enum ProfilePhotoService {
    private static let maxProfilePhotoBase64Bytes = 800_000
    private static let profilePhotoDimensions: [CGFloat] = [1024, 800, 640]
    private static let compressionQualities: [CGFloat] = [0.82, 0.72, 0.62, 0.52, 0.42]

    static func save(_ image: UIImage, userId: String) async throws -> UIImage {
        let uid = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty else {
            throw FirestoreRepositoryError.missingUserId
        }

        guard let processedPhoto = makeProfilePhoto(from: image) else {
            throw ProfilePhotoProcessingError.unableToProcess
        }

        LocalProfileStore.shared.setPhotoBase64(processedPhoto.base64, userId: uid)
        try await FirestoreRepository.shared.setUserPhotoBase64(
            uid: uid,
            photoBase64: processedPhoto.base64
        )

        return processedPhoto.image
    }

    static func clear(userId: String) async throws {
        let uid = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty else {
            throw FirestoreRepositoryError.missingUserId
        }

        LocalProfileStore.shared.clearPhoto(userId: uid)
        try await FirestoreRepository.shared.clearUserPhotoBase64(uid: uid)
    }

    private static func makeProfilePhoto(from image: UIImage) -> (image: UIImage, base64: String)? {
        for dimension in profilePhotoDimensions {
            guard let resizedImage = normalizedAndResizedImage(image, maximumDimension: dimension) else {
                return nil
            }

            for quality in compressionQualities {
                guard let data = resizedImage.jpegData(compressionQuality: quality) else {
                    continue
                }

                let base64 = data.base64EncodedString()
                if base64.utf8.count <= maxProfilePhotoBase64Bytes {
                    return (resizedImage, base64)
                }
            }
        }

        return nil
    }

    private static func normalizedAndResizedImage(
        _ image: UIImage,
        maximumDimension: CGFloat
    ) -> UIImage? {
        let sourceSize = image.size
        guard sourceSize.width > 0, sourceSize.height > 0 else {
            return nil
        }

        let scale = min(maximumDimension / max(sourceSize.width, sourceSize.height), 1)
        let targetSize = CGSize(
            width: (sourceSize.width * scale).rounded(.down),
            height: (sourceSize.height * scale).rounded(.down)
        )
        guard targetSize.width > 0, targetSize.height > 0 else {
            return nil
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
