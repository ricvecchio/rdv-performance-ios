import Foundation
import CoreData

/// Entidade Core Data que representa uma atividade do usuário
@objc(UserActivity)
public class UserActivity: NSManagedObject {
    /// Retorna fetch request configurado para buscar entidades UserActivity
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserActivity> {
        return NSFetchRequest<UserActivity>(entityName: "UserActivity")
    }

    /// Identificador único da atividade
    @NSManaged public var id: UUID?
    /// Título descritivo da atividade
    @NSManaged public var title: String?
    /// Data e hora da atividade
    @NSManaged public var date: Date?
}
