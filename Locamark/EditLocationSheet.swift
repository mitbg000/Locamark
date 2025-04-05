//
//  EditLocationSheet.swift
//  Locamark
//
//  Created by Chu Ba Manh on 08/03/2025.
//


import SwiftUI

struct EditLocationSheet: View {
    let location: LocationData
    @EnvironmentObject var locationViewModel: LocationViewModel
    @EnvironmentObject var localizationViewModel: LocalizationViewModel
    @State private var customName: String
    @State private var selectedCategory: LocationCategory
    @Environment(\.dismiss) var dismiss

    init(location: LocationData) {
        self.location = location
        self._customName = State(initialValue: location.customName ?? "")
        self._selectedCategory = State(initialValue: LocationCategory(rawValue: location.category ?? "other") ?? .other)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(localizationViewModel.localizedString("Edit Location"))) {
                    TextField(localizationViewModel.localizedString("Custom Name (optional)"), text: $customName)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                    Picker(localizationViewModel.localizedString("Category"), selection: $selectedCategory) {
                        ForEach(LocationCategory.allCases) { category in
                            Text(category.localizedName(using: localizationViewModel)).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    Text("\(localizationViewModel.localizedString("Detected")): \(location.locationName ?? localizationViewModel.localizedString("Unknown"))")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(localizationViewModel.localizedString("Edit Location"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizationViewModel.localizedString("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(localizationViewModel.localizedString("Save")) {
                        locationViewModel.updateLocation(location: location, customName: customName.isEmpty ? nil : customName, category: selectedCategory.rawValue)
                        dismiss()
                    }
                }
            }
        }
    }
}
