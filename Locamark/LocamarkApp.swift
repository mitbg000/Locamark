//
//  LocamarkApp.swift
//  Locamark
//
//  Created by Chu Ba Manh on 08/03/2025.
//


import SwiftUI

@main
struct LocamarkApp: App {
    @StateObject private var locationViewModel = LocationViewModel()
    @StateObject private var localizationViewModel = LocalizationViewModel()
    @StateObject private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationViewModel)
                .environmentObject(localizationViewModel)
                .environmentObject(locationManager)
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}
