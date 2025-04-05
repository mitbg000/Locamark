import Foundation
import CoreData

extension LocationData {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocationData> {
        return NSFetchRequest<LocationData>(entityName: "LocationData")
    }

    @NSManaged public var id: UUID
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var timestamp: Date?
    @NSManaged public var locationName: String?
    @NSManaged public var customName: String?
    @NSManaged public var category: String?
    @NSManaged public var language: String?
    @NSManaged public var isDarkMode: Bool
}

extension LocationData: Identifiable {
}
