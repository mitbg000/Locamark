//
//  LocationCategory.swift
//  Locamark
//
//  Created by Chu Ba Manh on 08/03/2025.
//


import SwiftUI

enum LocationCategory: String, CaseIterable, Identifiable {
    case work = "Work"
    case home = "Home"
    case travel = "Travel"
    case shopping = "Shopping"
    case restaurant = "Restaurant"
    case exercise = "Exercise"
    case other = "Other"
    
    var id: String { self.rawValue }

    func localizedName(using localizationViewModel: LocalizationViewModel) -> String {
        localizationViewModel.localizedString(self.rawValue)
    }
}