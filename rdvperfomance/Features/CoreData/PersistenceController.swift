import Foundation
import CoreData

/// PersistenceController: cria um NSPersistentContainer com um NSManagedObjectModel programático.
final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "RDVModel", managedObjectModel: model)

        if inMemory {
            let desc = NSPersistentStoreDescription()
            desc.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [desc]
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // Em desenvolvimento, logamos o erro; em produção trate apropriadamente
                print("Unresolved error loading persistent stores: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Entidade: UserActivity
        let entity = NSEntityDescription()
        entity.name = "UserActivity"
        entity.managedObjectClassName = String(describing: UserActivity.self)

        // Atributos
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = true

        let titleAttr = NSAttributeDescription()
        titleAttr.name = "title"
        titleAttr.attributeType = .stringAttributeType
        titleAttr.isOptional = true

        let dateAttr = NSAttributeDescription()
        dateAttr.name = "date"
        dateAttr.attributeType = .dateAttributeType
        dateAttr.isOptional = true

        entity.properties = [idAttr, titleAttr, dateAttr]

        model.entities = [entity]
        return model
    }

    // Helper: save context
    func saveContext(_ context: NSManagedObjectContext? = nil) throws {
        let ctx = context ?? container.viewContext
        if ctx.hasChanges {
            try ctx.save()
        }
    }
}
