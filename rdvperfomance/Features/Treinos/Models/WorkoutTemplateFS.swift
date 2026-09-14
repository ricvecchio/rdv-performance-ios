import Foundation
import FirebaseFirestore

struct WorkoutTemplateFS: Identifiable, Codable, Hashable {

    @DocumentID var id: String?

    var teacherId: String
    var categoryRaw: String
    var sectionKey: String

    var title: String
    var description: String

    // Para evoluir depois: blocos prontos do dia
    var blocks: [BlockFS]?

    @ServerTimestamp var createdAt: Timestamp?
    @ServerTimestamp var updatedAt: Timestamp?
}

