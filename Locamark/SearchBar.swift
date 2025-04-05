//
//  SearchBar.swift
//  Locamark
//
//  Created by Chu Ba Manh on 08/03/2025.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @EnvironmentObject var localizationViewModel: LocalizationViewModel

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColor.tagText)
                .accessibilityLabel("Search")
            TextField(localizationViewModel.localizedString("Search by name, note or category"), text: $text)
                .font(AppFont.body)
                .foregroundColor(AppColor.primaryText)
                .textFieldStyle(PlainTextFieldStyle())
                .submitLabel(.search)
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColor.tagText)
                        .accessibilityLabel("Clear search")
                }
            }
        }
        .searchBarStyle()
    }
}
