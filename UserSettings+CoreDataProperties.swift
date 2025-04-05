import Foundation
import CoreData

extension UserSettings {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserSettings> {
        return NSFetchRequest<UserSettings>(entityName: "UserSettings")
    }

    @NSManaged public var language: String?
    @NSManaged public var isDarkMode: NSNumber? // Sử dụng NSNumber thay vì Bool?
}

extension UserSettings : Identifiable {
    public var id: UUID { UUID() } // Hoặc sử dụng một thuộc tính khác nếu có
}
