import Foundation
import FirebaseFirestore

// Modelo de dia de treino armazenado no Firestore
struct TrainingDayFS: Identifiable, Codable, Hashable {

    @DocumentID var id: String?

    var dayIndex: Int
    var dayName: String
    var date: Date?

    var title: String
    var description: String
    var categoryRaw: String?

    var blocks: [BlockFS]

    @ServerTimestamp var createdAt: Timestamp?
    @ServerTimestamp var updatedAt: Timestamp?
}

// Modelo de bloco dentro de um dia de treino
struct BlockFS: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var details: String
}

extension TrainingDayFS {
    // Retorna texto formatado para exibir na UI
    func subtitleText(locale: Locale) -> String {
        let idx = max(dayIndex, 0) + 1
        let format = AppLocalization.string("ui.day_value_ld", locale: locale)
        let dayText = String(format: format, locale: locale, arguments: [Int64(idx)])

        if !dayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(dayName) • \(dayText)"
        }
        return dayText
    }

    var isVideoDay: Bool {
        blocks.contains { block in
            block.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare("Vídeo") == .orderedSame
                && YouTubeVideoImporter.extractYoutubeVideoId(
                    from: block.details.trimmingCharacters(in: .whitespacesAndNewlines)
                ) != nil
        }
    }
}
