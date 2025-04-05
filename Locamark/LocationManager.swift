//
//  LocationManager.swift
//  Locamark
//
//  Created by Chu Ba Manh on 08/03/2025.
//

import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private let locationIQApiKey = "pk.3314bfe2af4124f0d075cf1ac67cc360"

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkAuthorizationStatus()
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func checkAuthorizationStatus() {
        authorizationStatus = locationManager.authorizationStatus
        switch authorizationStatus {
        case .notDetermined:
            requestPermission()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location access denied or restricted.")
        @unknown default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkAuthorizationStatus()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        if let location = currentLocation {
            print("Updated location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        } else {
            print("No locations received in update.")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    func reverseGeocode(location: CLLocation, completion: @escaping (String?) -> Void) {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let urlString = "https://us1.locationiq.com/v1/reverse?key=\(locationIQApiKey)&lat=\(lat)&lon=\(lon)&format=json"
        guard let url = URL(string: urlString) else { print("Invalid URL: \(urlString)"); completion(nil); return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error { print("API error: \(error.localizedDescription)"); completion(nil); return }
            guard let data = data else { print("No data received"); completion("No Data Received"); return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let address = json["address"] as? [String: Any] {
                    let components = [address["road"], address["suburb"], address["city"], address["state"], address["country"]].compactMap { $0 as? String }
                    let locationName = components.joined(separator: ", ").isEmpty ? "Nearest Location Not Found" : components.joined(separator: ", ")
                    print("Location from LocationIQ: \(locationName)")
                    completion(locationName)
                } else { completion("Nearest Location Not Found") }
            } catch { print("JSON error: \(error.localizedDescription)"); completion("JSON Parsing Error") }
        }.resume()
    }
}
