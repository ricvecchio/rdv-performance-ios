import Foundation
import CoreData

@objc(UserActivity)
public class UserActivity: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserActivity> {
        return NSFetchRequest<UserActivity>(entityName: "UserActivity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var date: Date?
}
