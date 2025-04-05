//
//  LocationViewModel.swift
//  Locamark
//
//  Created by Chu Ba Manh on 08/03/2025.
//

import CoreData
import UIKit

class LocationViewModel: ObservableObject {
    let container: NSPersistentContainer
    @Published var locations: [LocationData] = []
    @Published var settings: LocationData?
    @Published var errorMessage: String?
    private let locationManager: LocationManager

    init(locationManager: LocationManager = LocationManager()) {
        self.locationManager = locationManager
        container = PersistenceController.shared.container
        container.loadPersistentStores { _, error in
            if let error = error { print("Core Data error: \(error.localizedDescription)") }
            else { self.fetchInitialData() }
        }
    }

    func fetchInitialData() {
        fetchLocations()
        fetchSettings()
    }

    func fetchLocations(with searchText: String = "", category: String? = nil) {
        let request: NSFetchRequest<LocationData> = LocationData.fetchRequest()
        var predicates: [NSPredicate] = [NSPredicate(format: "language == nil")]
        
        var searchPredicates: [NSPredicate] = []
        if !searchText.isEmpty {
            searchPredicates.append(NSPredicate(format: "locationName CONTAINS[cd] %@ OR customName CONTAINS[cd] %@ OR category CONTAINS[cd] %@",
                                                searchText.lowercased(), searchText.lowercased(), searchText.lowercased()))
        }
        
        if let category = category, !category.isEmpty {
            searchPredicates.append(NSPredicate(format: "category =[c] %@", category))
        }
        
        if !searchPredicates.isEmpty {
            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: searchPredicates)) // Sử dụng OR thay vì AND
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            let fetchedLocations = try container.viewContext.fetch(request)
            DispatchQueue.main.async {
                self.locations = fetchedLocations
                print("Fetched \(self.locations.count) locations with searchText: '\(searchText)', category: '\(category ?? "none")'")
            }
        } catch {
            print("Fetch locations error: \(error.localizedDescription)")
        }
    }

    func markCurrentLocation() {
        guard let location = locationManager.currentLocation else {
            print("No location available.")
            errorMessage = NSLocalizedString("No location available. Please ensure location services are enabled.", comment: "")
            return
        }
        errorMessage = nil
        locationManager.reverseGeocode(location: location) { locationName in
            let newLocation = self.saveLocation(latitude: location.coordinate.latitude,
                                                longitude: location.coordinate.longitude,
                                                timestamp: Date(),
                                                locationName: locationName ?? "Nearest Location Not Found",
                                                category: "other")
            DispatchQueue.main.async {
                self.locations.insert(newLocation, at: 0)
            }
        }
    }

    @discardableResult
    func saveLocation(latitude: Double, longitude: Double, timestamp: Date, locationName: String, customName: String? = nil, category: String) -> LocationData {
        let newLocation = LocationData(context: container.viewContext)
        newLocation.id = UUID()
        newLocation.latitude = latitude
        newLocation.longitude = longitude
        newLocation.timestamp = timestamp
        newLocation.locationName = locationName.isEmpty ? "Unknown" : locationName
        newLocation.customName = customName
        newLocation.category = category.isEmpty ? "other" : category
        newLocation.language = nil
        newLocation.isDarkMode = false
        do {
            try container.viewContext.save()
            print("Saved new location: \(newLocation.locationName ?? "Unknown") at \(timestamp)")
            return newLocation
        } catch {
            print("Save location error: \(error.localizedDescription)")
            return newLocation
        }
    }

    func updateLocation(location: LocationData, customName: String?, category: String) {
        location.customName = customName
        location.category = category.isEmpty ? "other" : category
        do {
            try container.viewContext.save()
            fetchLocations()
        } catch { print("Update location error: \(error.localizedDescription)") }
    }

    func deleteLocation(_ location: LocationData, completion: @escaping () -> Void) {
        let backgroundContext = container.newBackgroundContext()
        backgroundContext.perform {
            do {
                let request: NSFetchRequest<LocationData> = LocationData.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", location.id as CVarArg)
                request.fetchLimit = 1
                
                if let objectToDelete = try backgroundContext.fetch(request).first {
                    print("Attempting to delete location: \(objectToDelete.locationName ?? "Unknown"), ID: \(objectToDelete.id)")
                    backgroundContext.delete(objectToDelete)
                    try backgroundContext.save()
                    print("Successfully deleted location: \(objectToDelete.locationName ?? "Unknown")")
                } else {
                    print("Location with ID \(location.id) not found for deletion.")
                }
                
                DispatchQueue.main.async {
                    self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                    self.container.viewContext.performAndWait {
                        do {
                            try self.container.viewContext.save()
                            print("Merged changes into view context after deletion.")
                        } catch {
                            print("Error merging context after delete: \(error.localizedDescription)")
                        }
                    }
                    completion()
                }
            } catch {
                print("Delete location error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }

    func fetchSettings() {
        let request: NSFetchRequest<LocationData> = LocationData.fetchRequest()
        request.predicate = NSPredicate(format: "language != nil")
        request.fetchLimit = 1
        do {
            settings = try container.viewContext.fetch(request).first
            if settings == nil {
                settings = LocationData(context: container.viewContext)
                settings?.id = UUID()
                settings?.language = "en"
                settings?.isDarkMode = false
                try container.viewContext.save()
            }
        } catch { print("Fetch settings error: \(error.localizedDescription)") }
    }

    func shareLocation(_ location: LocationData) {
        let formattedDate = DateFormatter().then {
            $0.dateFormat = "dd/MM/yyyy HH:mm"
        }.string(from: location.timestamp ?? Date())
        let shareText = "I'm at \(location.customName ?? location.locationName ?? "Unknown") on \(formattedDate)!"
        let url = "https://maps.apple.com/?ll=\(location.latitude),\(location.longitude)"
        let activityController = UIActivityViewController(activityItems: [shareText, URL(string: url)!], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityController, animated: true)
        }
    }

    func openInMaps(_ location: LocationData) {
        let mapURL = "http://maps.apple.com/?ll=\(location.latitude),\(location.longitude)"
        if let url = URL(string: mapURL), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:])
        }
    }

    // Thêm hàm tạo mã QR từ thông tin vị trí
    func generateQRCode(from location: LocationData) -> UIImage? {
        let locationData = """
        Location: \(location.customName ?? location.locationName ?? "Unknown")
        Latitude: \(location.latitude)
        Longitude: \(location.longitude)
        Category: \(location.category ?? "other")
        Timestamp: \(DateFormatter().then { $0.dateFormat = "dd/MM/yyyy HH:mm" }.string(from: location.timestamp ?? Date()))
        """
        if let data = locationData.data(using: .utf8) {
            if let filter = CIFilter(name: "CIQRCodeGenerator") {
                filter.setValue(data, forKey: "inputMessage")
                filter.setValue("H", forKey: "inputCorrectionLevel")
                if let ciImage = filter.outputImage {
                    let transform = CGAffineTransform(scaleX: 10, y: 10)
                    let scaledCiImage = ciImage.transformed(by: transform)
                    if let cgImage = CIContext().createCGImage(scaledCiImage, from: scaledCiImage.extent) {
                        return UIImage(cgImage: cgImage)
                    }
                }
            }
        }
        return nil
    }
}

extension DateFormatter {
    func then(_ block: (DateFormatter) -> Void) -> DateFormatter {
        block(self)
        return self
    }
}
