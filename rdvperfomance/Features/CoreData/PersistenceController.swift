import Foundation
import CoreData

/// Controller que gerencia o NSPersistentContainer com modelo Core Data programático
final class PersistenceController {
    /// Instância singleton compartilhada
    static let shared = PersistenceController()

    /// Container persistente do Core Data
    let container: NSPersistentContainer

    /// Inicializa o controller com opção de armazenamento em memória para testes
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
                print("Unresolved error loading persistent stores: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    /// Cria o modelo de dados Core Data programaticamente
    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        /// Define a entidade UserActivity
        let entity = NSEntityDescription()
        entity.name = "UserActivity"
        entity.managedObjectClassName = String(describing: UserActivity.self)

        /// Atributo UUID identificador único
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = true

        /// Atributo título da atividade
        let titleAttr = NSAttributeDescription()
        titleAttr.name = "title"
        titleAttr.attributeType = .stringAttributeType
        titleAttr.isOptional = true

        /// Atributo data da atividade
        let dateAttr = NSAttributeDescription()
        dateAttr.name = "date"
        dateAttr.attributeType = .dateAttributeType
        dateAttr.isOptional = true

        entity.properties = [idAttr, titleAttr, dateAttr]

        model.entities = [entity]
        return model
    }

    /// Salva o contexto fornecido ou o contexto principal se houver mudanças
    func saveContext(_ context: NSManagedObjectContext? = nil) throws {
        let ctx = context ?? container.viewContext
        if ctx.hasChanges {
            try ctx.save()
        }
    }
}
